#!/usr/bin/env bash
# ==============================================================================
#  HeadUnit OS — OpenAuto + AASDK Wireless Android Auto Installer
#  Supported: Raspberry Pi OS (Bookworm/Bullseye), Ubuntu 22.04, Linux Mint 21+
#  Usage: bash scripts/install_openauto.sh
# ==============================================================================
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     HeadUnit OS — OpenAuto Wireless Android Auto Installer  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 0. Checks ─────────────────────────────────────────────────────────────────

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This script is for Linux only. On Windows, use the Windows simulation mode."
fi

if [[ $EUID -eq 0 ]]; then
  warn "Running as root. Consider running as a regular user (sudo is called internally)."
fi

BUILD_DIR="/tmp/headunit_openauto_build"
INSTALL_PREFIX="/usr/local"
CONFIG_DIR="$HOME/.config/openauto"
HOTSPOT_SSID="HeadUnit-OS"
HOTSPOT_PASS="headunit2024"
HOTSPOT_CONN_NAME="HeadUnit-OS"
BT_ALIAS="HeadUnit-OS"
AA_VIDEO_PORT="5556"
AA_WIRELESS_PORT="5288"

mkdir -p "$BUILD_DIR"

# ── 1. System dependencies ────────────────────────────────────────────────────
info "Step 1/6 — Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  build-essential cmake git pkg-config \
  libusb-1.0-0-dev libssl-dev \
  libprotobuf-dev protobuf-compiler \
  libpulse-dev pulseaudio \
  libboost-all-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  libbluetooth-dev bluez rfkill \
  network-manager \
  librtaudio-dev \
  qtbase5-dev qtmultimedia5-dev \
  qtconnectivity5-dev \
  libavcodec-dev libavformat-dev libavutil-dev libswscale-dev
success "Build dependencies installed."

# ── 2. Build aasdk ────────────────────────────────────────────────────────────
info "Step 2/6 — Building aasdk (Android Auto SDK)..."
cd "$BUILD_DIR"
# Always re-clone fresh rather than reusing a directory left behind by a
# previous run: an existing checkout from before a patch was added here
# would silently skip re-cloning *and* re-patching, and "make" would just
# resume building the stale, unpatched tree (this is exactly what caused
# the LIBUSB_HOTPLUG_NO_FLAGS build failure below to persist across runs).
rm -rf aasdk
git clone --depth=1 https://github.com/f1xpl/aasdk.git

info "Patching aasdk for Boost 1.70+, OpenSSL 3.0, and API compatibility..."
find aasdk -type f -name "*.cpp" -exec sed -i 's/get_io_service()/context()/g' {} +
sed -i '1s/^/#include <boost\/core\/noncopyable.hpp>\n/' aasdk/include/f1x/aasdk/IO/Promise.hpp
sed -i 's/FIPS_mode_set(0);//g' aasdk/src/Transport/SSLWrapper.cpp

# Make onAVChannelStopIndication a default virtual function instead of pure virtual (= 0)
python3 -c "
import glob
for path in glob.glob('aasdk/**/*.hpp', recursive=True):
    with open(path, 'r') as f:
        content = f.read()
    if 'onAVChannelStopIndication' in content:
        content = content.replace('virtual void onAVChannelStopIndication(const proto::messages::AVChannelStopIndication& indication) = 0;', 'virtual void onAVChannelStopIndication(const proto::messages::AVChannelStopIndication& indication) {}')
        with open(path, 'w') as f:
            f.write(content)
"

# libusb 1.0.27 made libusb_hotplug_flag a real enum; aasdk passes the bare
# LIBUSB_HOTPLUG_NO_FLAGS macro (an int) into that parameter with no cast,
# which newer GCC rejects outright. Cast it explicitly rather than relying
# on -fpermissive alone.
sed -i 's/LIBUSB_HOTPLUG_NO_FLAGS/static_cast<libusb_hotplug_flag>(LIBUSB_HOTPLUG_NO_FLAGS)/g' \
  aasdk/src/USB/USBHub.cpp

info "Patching aasdk MessageInStream for concurrent multi-channel message reassembly..."
# vanilla aasdk tracks exactly ONE in-progress multi-frame message globally
# (a single message_ member in MessageInStream). The physical transport is
# shared by every channel, and frames from different channels legitimately
# interleave on the wire once more than one channel streams continuously at
# once (e.g. video + media audio both active) — vanilla rejects that as
# MESSENGER_INTERTWINED_CHANNELS, which made concurrent audio+video AA
# sessions fail within milliseconds of the audio channel opening. Fix:
# track one in-progress message PER CHANNEL (a map keyed by ChannelId)
# instead of a single global one, so each channel's partial message
# survives independently until its own final frame arrives. Reconstructed
# and verified live 2026-08-09 — see memory: aa-audio-through-headunit.
python3 -c "
path = 'aasdk/include/f1x/aasdk/Messenger/MessageInStream.hpp'
with open(path) as f:
    content = f.read()

if '#include <map>' not in content:
    content = content.replace(
        '#include <f1x/aasdk/Messenger/FrameSize.hpp>',
        '#include <f1x/aasdk/Messenger/FrameSize.hpp>\n#include <map>',
        1)

old_members = '''    FrameType recentFrameType_;
    ReceivePromise::Pointer promise_;
    Message::Pointer message_;'''
new_members = '''    FrameType recentFrameType_;
    ReceivePromise::Pointer promise_;
    std::map<ChannelId, Message::Pointer> pendingMessages_;
    ChannelId currentChannelId_;'''
assert old_members in content, 'MessageInStream.hpp member block not found — aasdk source may have changed upstream'
content = content.replace(old_members, new_members)

with open(path, 'w') as f:
    f.write(content)

path = 'aasdk/src/Messenger/MessageInStream.cpp'
with open(path) as f:
    content = f.read()

# Normalize trailing whitespace per line so the multi-line literal matches
# below don't silently fail on invisible trailing spaces in the original
# source (e.g. '{   \n' instead of '{\n').
content = '\n'.join(line.rstrip() for line in content.split('\n'))

old_header_handler = '''void MessageInStream::receiveFrameHeaderHandler(const common::DataConstBuffer& buffer)
{
    FrameHeader frameHeader(buffer);

    if(message_ == nullptr)
    {
        message_ = std::make_shared<Message>(frameHeader.getChannelId(), frameHeader.getEncryptionType(), frameHeader.getMessageType());
    }
    else if(message_->getChannelId() != frameHeader.getChannelId())
    {
        message_.reset();
        promise_->reject(error::Error(error::ErrorCode::MESSENGER_INTERTWINED_CHANNELS));
        promise_.reset();
        return;
    }

    recentFrameType_ = frameHeader.getType();
    const size_t frameSize = FrameSize::getSizeOf(frameHeader.getType() == FrameType::FIRST ? FrameSizeType::EXTENDED : FrameSizeType::SHORT);

    auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
    transportPromise->then(
        [this, self = this->shared_from_this()](common::Data data) mutable {
            this->receiveFrameSizeHandler(common::DataConstBuffer(data));
        },
        [this, self = this->shared_from_this()](const error::Error& e) mutable {
            message_.reset();
            promise_->reject(e);
            promise_.reset();
        });

    transport_->receive(frameSize, std::move(transportPromise));
}'''

new_header_handler = '''void MessageInStream::receiveFrameHeaderHandler(const common::DataConstBuffer& buffer)
{
    FrameHeader frameHeader(buffer);
    currentChannelId_ = frameHeader.getChannelId();

    if(pendingMessages_.find(currentChannelId_) == pendingMessages_.end())
    {
        pendingMessages_.emplace(currentChannelId_,
            std::make_shared<Message>(frameHeader.getChannelId(), frameHeader.getEncryptionType(), frameHeader.getMessageType()));
    }

    recentFrameType_ = frameHeader.getType();
    const size_t frameSize = FrameSize::getSizeOf(frameHeader.getType() == FrameType::FIRST ? FrameSizeType::EXTENDED : FrameSizeType::SHORT);

    auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
    transportPromise->then(
        [this, self = this->shared_from_this()](common::Data data) mutable {
            this->receiveFrameSizeHandler(common::DataConstBuffer(data));
        },
        [this, self = this->shared_from_this()](const error::Error& e) mutable {
            pendingMessages_.erase(currentChannelId_);
            promise_->reject(e);
            promise_.reset();
        });

    transport_->receive(frameSize, std::move(transportPromise));
}'''

assert old_header_handler in content, 'receiveFrameHeaderHandler not found — aasdk source may have changed upstream'
content = content.replace(old_header_handler, new_header_handler)

old_size_handler = '''void MessageInStream::receiveFrameSizeHandler(const common::DataConstBuffer& buffer)
{
    auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
    transportPromise->then(
        [this, self = this->shared_from_this()](common::Data data) mutable {
            this->receiveFramePayloadHandler(common::DataConstBuffer(data));
        },
        [this, self = this->shared_from_this()](const error::Error& e) mutable {
            message_.reset();
            promise_->reject(e);
            promise_.reset();
        });

    FrameSize frameSize(buffer);
    transport_->receive(frameSize.getSize(), std::move(transportPromise));
}'''

new_size_handler = '''void MessageInStream::receiveFrameSizeHandler(const common::DataConstBuffer& buffer)
{
    auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
    transportPromise->then(
        [this, self = this->shared_from_this()](common::Data data) mutable {
            this->receiveFramePayloadHandler(common::DataConstBuffer(data));
        },
        [this, self = this->shared_from_this()](const error::Error& e) mutable {
            pendingMessages_.erase(currentChannelId_);
            promise_->reject(e);
            promise_.reset();
        });

    FrameSize frameSize(buffer);
    transport_->receive(frameSize.getSize(), std::move(transportPromise));
}'''

assert old_size_handler in content, 'receiveFrameSizeHandler not found — aasdk source may have changed upstream'
content = content.replace(old_size_handler, new_size_handler)

old_payload_handler = '''void MessageInStream::receiveFramePayloadHandler(const common::DataConstBuffer& buffer)
{
    if(message_->getEncryptionType() == EncryptionType::ENCRYPTED)
    {
        try
        {
            cryptor_->decrypt(message_->getPayload(), buffer);
        }
        catch(const error::Error& e)
        {
            message_.reset();
            promise_->reject(e);
            promise_.reset();
            return;
        }
    }
    else
    {
        message_->insertPayload(buffer);
    }

    if(recentFrameType_ == FrameType::BULK || recentFrameType_ == FrameType::LAST)
    {
        promise_->resolve(std::move(message_));
        promise_.reset();
    }
    else
    {
        auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
        transportPromise->then(
            [this, self = this->shared_from_this()](common::Data data) mutable {
                this->receiveFrameHeaderHandler(common::DataConstBuffer(data));
            },
            [this, self = this->shared_from_this()](const error::Error& e) mutable {
                message_.reset();
                promise_->reject(e);
                promise_.reset();
            });

        transport_->receive(FrameHeader::getSizeOf(), std::move(transportPromise));
    }
}'''

new_payload_handler = '''void MessageInStream::receiveFramePayloadHandler(const common::DataConstBuffer& buffer)
{
    Message::Pointer currentMessage = pendingMessages_.at(currentChannelId_);

    if(currentMessage->getEncryptionType() == EncryptionType::ENCRYPTED)
    {
        try
        {
            cryptor_->decrypt(currentMessage->getPayload(), buffer);
        }
        catch(const error::Error& e)
        {
            pendingMessages_.erase(currentChannelId_);
            promise_->reject(e);
            promise_.reset();
            return;
        }
    }
    else
    {
        currentMessage->insertPayload(buffer);
    }

    if(recentFrameType_ == FrameType::BULK || recentFrameType_ == FrameType::LAST)
    {
        pendingMessages_.erase(currentChannelId_);
        promise_->resolve(std::move(currentMessage));
        promise_.reset();
    }
    else
    {
        auto transportPromise = transport::ITransport::ReceivePromise::defer(strand_);
        transportPromise->then(
            [this, self = this->shared_from_this()](common::Data data) mutable {
                this->receiveFrameHeaderHandler(common::DataConstBuffer(data));
            },
            [this, self = this->shared_from_this()](const error::Error& e) mutable {
                pendingMessages_.erase(currentChannelId_);
                promise_->reject(e);
                promise_.reset();
            });

        transport_->receive(FrameHeader::getSizeOf(), std::move(transportPromise));
    }
}'''

assert old_payload_handler in content, 'receiveFramePayloadHandler not found — aasdk source may have changed upstream'
content = content.replace(old_payload_handler, new_payload_handler)

with open(path, 'w') as f:
    f.write(content)
print('aasdk MessageInStream patched OK')
"

cd aasdk
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fpermissive" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
make -j"$(nproc)"

# aasdk's CMakeLists.txt defines no install() rules at all — "make install"
# fails with "No rule to make target 'install'" every time. Stage the known
# build output locations manually instead: shared libs land in ../lib/,
# hand-written headers in ../include/f1x/, and the protoc-generated
# aasdk_proto headers land in aasdk_proto/ inside this build directory.
if ! sudo make install 2>/dev/null; then
  warn "aasdk has no 'make install' target — staging build output into $INSTALL_PREFIX manually."
  sudo install -d "$INSTALL_PREFIX/include" "$INSTALL_PREFIX/include/aasdk_proto" "$INSTALL_PREFIX/lib"
  sudo cp -r ../include/f1x "$INSTALL_PREFIX/include/"
  sudo cp aasdk_proto/*.pb.h "$INSTALL_PREFIX/include/aasdk_proto/"
  sudo cp -P ../lib/libaasdk.so ../lib/libaasdk_proto.so "$INSTALL_PREFIX/lib/"
fi
sudo ldconfig
success "aasdk installed to $INSTALL_PREFIX."

# ── 3. Build openauto ─────────────────────────────────────────────────────────
info "Step 3/6 — Building openauto..."
cd "$BUILD_DIR"
rm -rf openauto
git clone --depth=1 https://github.com/f1xpl/openauto.git

info "Patching openauto for Boost 1.70+ compatibility..."
find openauto -type f -name "*.cpp" -exec sed -i 's/get_io_service()/context()/g' {} +

info "Patching openauto for HeadUnit OS display handover + reconnect + ping keepalive..."
# Three behavioral changes on top of vanilla f1xpl/openauto, reconstructed
# 2026-08-09 after the original hand-patched checkout was lost with no
# backup (see memory: openauto-deployed-source-lost). Keep this patch here
# — in the repo, not as an ephemeral device-local checkout — so it is never
# lost again.
python3 -c "
import re

app_cpp = 'openauto/src/autoapp/App.cpp'
with open(app_cpp) as f:
    content = f.read()

if '#include <cstdlib>' not in content:
    content = content.replace(
        'along with openauto. If not, see <http://www.gnu.org/licenses/>.\n*/',
        'along with openauto. If not, see <http://www.gnu.org/licenses/>.\n*/\n#include <cstdlib>\n#include <boost/asio/deadline_timer.hpp>',
        1)

# 1) enumerateDevices(): pick up a phone that's already in AOAP accessory
#    mode at startup instead of only reacting to a fresh USB hotplug event —
#    needed because openauto.service starts on demand, after the phone may
#    have already been switched into accessory mode. A 750ms settle delay
#    before reopening it is required: the enumerator's own accessory-mode
#    query chain may have just switched the device into AOAP mode, which
#    triggers a full USB re-enumeration on the device side (standard AOA
#    protocol behavior). Opening it again immediately races that
#    re-enumeration and can grab a handle that isn't ready yet, failing
#    every channel within milliseconds of connecting (AaSdk error 26) —
#    which then looks like the USB tap silently did nothing, since
#    quick_exit-on-disconnect restores HeadUnit OS before anyone can see
#    it. Confirmed via live testing 2026-08-09: without the delay, the
#    very first tap after a fresh plug-in reliably failed this way and
#    needed a second tap to succeed; with it, the first tap works.
old_enum = '''void App::enumerateDevices()
{
    auto promise = aasdk::usb::IConnectedAccessoriesEnumerator::Promise::defer(strand_);
    promise->then([this, self = this->shared_from_this()](auto result) {
            OPENAUTO_LOG(info) << \"[App] Devices enumeration result: \" << result;
        },
        [this, self = this->shared_from_this()](auto e) {
            OPENAUTO_LOG(error) << \"[App] Devices enumeration failed: \" << e.what();
        });

    connectedAccessoriesEnumerator_->enumerate(std::move(promise));
}'''
new_enum = '''void App::enumerateDevices()
{
    OPENAUTO_LOG(info) << \"[App] Checking for already connected AOAP accessories...\";

    auto promise = aasdk::usb::IConnectedAccessoriesEnumerator::Promise::defer(strand_);
    promise->then([this, self = this->shared_from_this()](auto result) {
            OPENAUTO_LOG(info) << \"[App] Devices enumeration result: \" << result;

            if(result && androidAutoEntity_ == nullptr)
            {
                OPENAUTO_LOG(info) << \"[App] Found existing connected AOAP accessory! Connecting immediately...\";

                auto timer = std::make_shared<boost::asio::deadline_timer>(ioService_, boost::posix_time::milliseconds(750));
                timer->async_wait(strand_.wrap([this, self, timer](const boost::system::error_code&) {
                    if(androidAutoEntity_ != nullptr)
                    {
                        return;
                    }

                    auto deviceHandle = usbWrapper_.openDeviceWithVidPid(0x18D1, 0x2D00);
                    if(deviceHandle == nullptr)
                    {
                        deviceHandle = usbWrapper_.openDeviceWithVidPid(0x18D1, 0x2D01);
                    }

                    if(deviceHandle != nullptr)
                    {
                        OPENAUTO_LOG(info) << \"[App] Successfully opened existing AOAP accessory handle!\";
                        this->aoapDeviceHandler(std::move(deviceHandle));
                    }
                }));
            }
        },
        [this, self = this->shared_from_this()](auto e) {
            OPENAUTO_LOG(error) << \"[App] Devices enumeration failed: \" << e.what();
        });

    connectedAccessoriesEnumerator_->enumerate(std::move(promise));
}'''
assert old_enum in content, 'enumerateDevices() pattern not found — openauto source may have changed upstream'
content = content.replace(old_enum, new_enum)

# 2) onAndroidAutoQuit(): exit the process immediately on disconnect instead
#    of looping back to wait for another device. autoapp deadlocking inside
#    a graceful QApplication::quit() previously left headunit.service unable
#    to reclaim the display on unplug — quick_exit sidesteps that entirely.
old_quit = '''void App::onAndroidAutoQuit()
{
    strand_.dispatch([this, self = this->shared_from_this()]() {
        OPENAUTO_LOG(info) << \"[App] quit.\";

        androidAutoEntity_->stop();
        androidAutoEntity_.reset();

        if(!isStopped_)
        {
            this->waitForDevice();
        }
    });
}'''
new_quit = '''void App::onAndroidAutoQuit()
{
    strand_.dispatch([this, self = this->shared_from_this()]() {
        OPENAUTO_LOG(info) << \"[App] Phone disconnected. Exiting immediately to restore HeadUnit OS...\";

        androidAutoEntity_->stop();
        androidAutoEntity_.reset();

        std::quick_exit(0);
    });
}'''
assert old_quit in content, 'onAndroidAutoQuit() pattern not found — openauto source may have changed upstream'
content = content.replace(old_quit, new_quit)

# 3) onUSBHubError(): same immediate-exit reasoning as above, for the USB
#    hub error path.
old_err = '''void App::onUSBHubError(const aasdk::error::Error& error)
{
    OPENAUTO_LOG(error) << \"[App] usb hub error: \" << error.what();

    if(error != aasdk::error::ErrorCode::OPERATION_ABORTED &&
       error != aasdk::error::ErrorCode::OPERATION_IN_PROGRESS)
    {
        this->waitForDevice();
    }
}'''
new_err = '''void App::onUSBHubError(const aasdk::error::Error& error)
{
    OPENAUTO_LOG(error) << \"[App] usb hub error: \" << error.what();

    if(error != aasdk::error::ErrorCode::OPERATION_ABORTED &&
       error != aasdk::error::ErrorCode::OPERATION_IN_PROGRESS)
    {
        OPENAUTO_LOG(info) << \"[App] USB error - exiting immediately to restore HeadUnit OS...\";
        std::quick_exit(0);
    }
}'''
assert old_err in content, 'onUSBHubError() pattern not found — openauto source may have changed upstream'
content = content.replace(old_err, new_err)

with open(app_cpp, 'w') as f:
    f.write(content)

# 4) sendPing(): PingRequest.timestamp was never set (always 0). Modern
#    Android Auto clients silently stop answering unstamped pings after a
#    grace period, killing sessions at a consistent ~60s with 'ping timer
#    exceeded' even though the USB transport stays healthy the whole time
#    (confirmed via usbmon capture). f1xpl/openauto PR #185 made the same
#    fix independently in 2020 (never merged, unrelated to why it was
#    rejected).
entity_cpp = 'openauto/src/autoapp/Service/AndroidAutoEntity.cpp'
with open(entity_cpp) as f:
    content = f.read()

if '#include <chrono>' not in content:
    content = content.replace(
        '#include <f1x/openauto/Common/Log.hpp>',
        '#include <f1x/openauto/Common/Log.hpp>\n#include <chrono>',
        1)

old_ping = '''void AndroidAutoEntity::sendPing()
{
    auto promise = aasdk::channel::SendPromise::defer(strand_);
    promise->then([]() {}, std::bind(&AndroidAutoEntity::onChannelError, this->shared_from_this(), std::placeholders::_1));

    aasdk::proto::messages::PingRequest request;
    controlServiceChannel_->sendPingRequest(request, std::move(promise));
}'''
new_ping = '''void AndroidAutoEntity::sendPing()
{
    auto promise = aasdk::channel::SendPromise::defer(strand_);
    promise->then([]() {}, std::bind(&AndroidAutoEntity::onChannelError, this->shared_from_this(), std::placeholders::_1));

    auto timestamp = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::high_resolution_clock::now().time_since_epoch());

    aasdk::proto::messages::PingRequest request;
    request.set_timestamp(timestamp.count());
    controlServiceChannel_->sendPingRequest(request, std::move(promise));
}'''
assert old_ping in content, 'sendPing() pattern not found — openauto source may have changed upstream'
content = content.replace(old_ping, new_ping)

with open(entity_cpp, 'w') as f:
    f.write(content)

# 5) autoapp.cpp: size MainWindow to the real screen before making it
#    fullscreen. MainWindow.ui is Qt-Designer-authored at a fixed 800x480
#    with absolutely-positioned children (no layout manager). Under Qt's
#    eglfs platform (no window manager), showFullScreen() alone does not
#    reliably resize a window that combines Qt::WindowStaysOnTopHint with
#    an explicit small Designer geometry — it stays pinned at 800x480 in
#    the corner of the real display instead of filling it.
main_cpp = 'openauto/src/autoapp/autoapp.cpp'
with open(main_cpp) as f:
    content = f.read()

if '#include <QScreen>' not in content:
    content = content.replace('#include <QApplication>', '#include <QApplication>\n#include <QScreen>', 1)

old_mw = '''    autoapp::ui::MainWindow mainWindow;
    mainWindow.setWindowFlags(Qt::WindowStaysOnTopHint);'''
new_mw = '''    autoapp::ui::MainWindow mainWindow;
    mainWindow.setWindowFlags(Qt::WindowStaysOnTopHint);
    mainWindow.setGeometry(QGuiApplication::primaryScreen()->geometry());'''
assert old_mw in content, 'autoapp.cpp MainWindow setup pattern not found — openauto source may have changed upstream'
content = content.replace(old_mw, new_mw)

# 6) autoapp.cpp: never show MainWindow at all. This is a headless kiosk
#    deployment — connect/disconnect is driven entirely by systemd + the
#    HeadUnit OS Flutter app, nobody interacts with this window's
#    Settings/Wireless/Exit buttons, and showing it just flashes an
#    unwanted \"Waiting for device\" screen during every display handover.
old_show = '''    mainWindow.showFullScreen();'''
new_show = '''    mainWindow.hide();'''
assert old_show in content, 'mainWindow.showFullScreen() line not found — openauto source may have changed upstream'
content = content.replace(old_show, new_show)

with open(main_cpp, 'w') as f:
    f.write(content)

# 7) QtVideoOutput.cpp: same screen-geometry-before-fullscreen fix as (5),
#    applied to the actual AA video widget (a separate top-level window
#    from MainWindow, also WindowStaysOnTopHint) — otherwise the video
#    content itself stays pinned to its small default size even once
#    MainWindow itself is sized/hidden correctly.
video_cpp = 'openauto/src/autoapp/Projection/QtVideoOutput.cpp'
with open(video_cpp) as f:
    content = f.read()

if '#include <QScreen>' not in content:
    content = content.replace('#include <QApplication>', '#include <QApplication>\n#include <QScreen>', 1)

old_vw = '''    videoWidget_->setAspectRatioMode(Qt::IgnoreAspectRatio);
    videoWidget_->setFocus();
    videoWidget_->setWindowFlags(Qt::WindowStaysOnTopHint);
    videoWidget_->setFullScreen(true);
    videoWidget_->show();'''
new_vw = '''    videoWidget_->setAspectRatioMode(Qt::IgnoreAspectRatio);
    videoWidget_->setFocus();
    videoWidget_->setWindowFlags(Qt::WindowStaysOnTopHint);
    videoWidget_->setGeometry(QGuiApplication::primaryScreen()->geometry());
    videoWidget_->setFullScreen(true);
    videoWidget_->show();'''
assert old_vw in content, 'QtVideoOutput.cpp onStartPlayback pattern not found — openauto source may have changed upstream'
content = content.replace(old_vw, new_vw)

with open(video_cpp, 'w') as f:
    f.write(content)

print('openauto custom patches applied OK')
"

cd openauto
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fpermissive" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
  -DAASDK_INCLUDE_DIRS="$INSTALL_PREFIX/include" \
  -DAASDK_LIBRARIES="$INSTALL_PREFIX/lib/libaasdk.so;$INSTALL_PREFIX/lib/libaasdk_proto.so"
make -j"$(nproc)"

# Same author, same era as aasdk — assume it may also lack install() rules
# rather than guess its layout. If "make install" doesn't exist, locate the
# built autoapp binary directly instead of hardcoding a path that might be
# wrong for this checkout.
if ! sudo make install 2>/dev/null; then
  warn "openauto has no 'make install' target — locating the built autoapp binary manually."
  # openauto's CMakeLists.txt sets RUNTIME_OUTPUT_DIRECTORY to the source
  # tree's own bin/, a sibling of build/ — not inside it. Search the whole
  # openauto checkout (..), not just the build directory.
  AUTOAPP_BIN=$(find .. -maxdepth 4 -type f -name autoapp -perm -u+x | head -1)
  if [[ -z "$AUTOAPP_BIN" ]]; then
    error "Could not locate a built 'autoapp' binary under $(cd .. && pwd). Check the build output above for errors."
  fi
  sudo install -d "$INSTALL_PREFIX/bin"
  sudo install -m 755 "$AUTOAPP_BIN" "$INSTALL_PREFIX/bin/autoapp"
fi
success "openauto installed — binary at $INSTALL_PREFIX/bin/autoapp"

# ── 4. OpenAuto configuration ─────────────────────────────────────────────────
info "Step 4/6 — Writing OpenAuto configuration..."
# openauto's Configuration class reads/writes a plain "openauto.ini" using a
# RELATIVE path (src/autoapp/Configuration/Configuration.cpp), resolved
# against the process's current working directory — i.e. openauto.service's
# WorkingDirectory (scripts/install_wired_aa.sh sets this to the kiosk
# user's $HOME). $CONFIG_DIR/openauto_properties.cfg below is NOT the file
# the app actually reads; it's kept only for the operator to see the values
# in one place. The real section/key names also differ from what you might
# guess (discovered 2026-08-09 chasing a "video renders at 800x480 in the
# corner" bug): [Video] Resolution=3 means 1080p (aasdk's VideoResolution
# enum: 1=480p, 2=720p, 3=1080p), FPS=2 means 60fps (VideoFPS enum: 1=30,
# 2=60) — these are NOT pixel dimensions or literal fps numbers.
AUTOAPP_WORKDIR="$HOME"
cat > "$AUTOAPP_WORKDIR/openauto.ini" << EOF
[General]
HandednessOfTrafficType=0
ShowClock=true
[Video]
FPS=2
Resolution=3
ScreenDPI=140
OMXLayerIndex=1
MarginWidth=0
MarginHeight=0
[Input]
EnableTouchscreen=true
[Bluetooth]
AdapterType=0
[Audio]
OutputBackendType=1
MusicAudioChannelEnabled=true
SpeechAudioChannelEnabled=true
EOF
success "Config written to $AUTOAPP_WORKDIR/openauto.ini (the file openauto.service's autoapp actually reads)"

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/openauto_properties.cfg" << EOF
[Main]
WirelessEnabled=true
WirelessPort=${AA_WIRELESS_PORT}
VideoWidth=1920
VideoHeight=1080
VideoFPS=60
VideoCodec=H264
VideoOutputPort=${AA_VIDEO_PORT}
AudioPort=5557
AudioOutputBackend=pulseaudio
BluetoothEnabled=true
BluetoothServiceName=${BT_ALIAS}
EOF
success "Reference copy written to $CONFIG_DIR/openauto_properties.cfg (informational only, not read by autoapp)"

# ── 5. Wi-Fi hotspot profile (nmcli) ─────────────────────────────────────────
info "Step 5/6 — Creating Wi-Fi hotspot profile (nmcli)..."
nmcli connection delete "$HOTSPOT_CONN_NAME" 2>/dev/null || true
nmcli connection add \
  type wifi \
  con-name "$HOTSPOT_CONN_NAME" \
  ssid "$HOTSPOT_SSID" \
  mode ap \
  ipv4.method shared \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "$HOTSPOT_PASS" \
  autoconnect no
success "Hotspot profile created: SSID='$HOTSPOT_SSID' password='$HOTSPOT_PASS'"

# ── 6. Bluetooth setup ────────────────────────────────────────────────────────
info "Step 6/6 — Configuring Bluetooth..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
bluetoothctl system-alias "$BT_ALIAS" 2>/dev/null || warn "Could not set BT alias (device may not be present)"
success "Bluetooth configured as: $BT_ALIAS"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Installation Complete!                    ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  OpenAuto binary : $INSTALL_PREFIX/bin/autoapp               ${NC}"
echo -e "${GREEN}║  Config file     : $CONFIG_DIR/                              ${NC}"
echo -e "${GREEN}║  Wi-Fi SSID      : $HOTSPOT_SSID                             ${NC}"
echo -e "${GREEN}║  Wi-Fi Password  : $HOTSPOT_PASS                         ${NC}"
echo -e "${GREEN}║  BT Device Name  : $BT_ALIAS                                ${NC}"
echo -e "${GREEN}║  Video UDP port  : $AA_VIDEO_PORT                            ${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Launch HeadUnit OS and tap 'Android Auto' to connect.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
