import os
import sys

def patch_openauto(openauto_dir):
    print(f"Applying custom patches to {openauto_dir}...")

    # 1) App.cpp patches
    app_cpp = os.path.join(openauto_dir, "src/autoapp/App.cpp")
    with open(app_cpp, "r") as f:
        content = f.read()

    if "#include <cstdlib>" not in content:
        content = content.replace(
            "along with openauto. If not, see <http://www.gnu.org/licenses/>.\n*/",
            "along with openauto. If not, see <http://www.gnu.org/licenses/>.\n*/\n#include <cstdlib>\n#include <boost/asio/deadline_timer.hpp>",
            1
        )

    old_enum = """void App::enumerateDevices()
{
    auto promise = aasdk::usb::IConnectedAccessoriesEnumerator::Promise::defer(strand_);
    promise->then([this, self = this->shared_from_this()](auto result) {
            OPENAUTO_LOG(info) << "[App] Devices enumeration result: " << result;
        },
        [this, self = this->shared_from_this()](auto e) {
            OPENAUTO_LOG(error) << "[App] Devices enumeration failed: " << e.what();
        });

    connectedAccessoriesEnumerator_->enumerate(std::move(promise));
}"""
    new_enum = """void App::enumerateDevices()
{
    OPENAUTO_LOG(info) << "[App] Checking for already connected AOAP accessories...";

    auto promise = aasdk::usb::IConnectedAccessoriesEnumerator::Promise::defer(strand_);
    promise->then([this, self = this->shared_from_this()](auto result) {
            OPENAUTO_LOG(info) << "[App] Devices enumeration result: " << result;

            if(result && androidAutoEntity_ == nullptr)
            {
                OPENAUTO_LOG(info) << "[App] Found existing connected AOAP accessory! Connecting immediately...";

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
                        OPENAUTO_LOG(info) << "[App] Successfully opened existing AOAP accessory handle!";
                        this->aoapDeviceHandler(std::move(deviceHandle));
                    }
                }));
            }
        },
        [this, self = this->shared_from_this()](auto e) {
            OPENAUTO_LOG(error) << "[App] Devices enumeration failed: " << e.what();
        });

    connectedAccessoriesEnumerator_->enumerate(std::move(promise));
}"""
    if old_enum in content:
        content = content.replace(old_enum, new_enum)

    old_quit = """void App::onAndroidAutoQuit()
{
    strand_.dispatch([this, self = this->shared_from_this()]() {
        OPENAUTO_LOG(info) << "[App] quit.";

        androidAutoEntity_->stop();
        androidAutoEntity_.reset();

        if(!isStopped_)
        {
            this->waitForDevice();
        }
    });
}"""
    new_quit = """void App::onAndroidAutoQuit()
{
    strand_.dispatch([this, self = this->shared_from_this()]() {
        OPENAUTO_LOG(info) << "[App] Phone disconnected. Exiting immediately to restore HeadUnit OS...";

        androidAutoEntity_->stop();
        androidAutoEntity_.reset();

        std::quick_exit(0);
    });
}"""
    if old_quit in content:
        content = content.replace(old_quit, new_quit)

    with open(app_cpp, "w") as f:
        f.write(content)

    # 2) AndroidAutoEntity.cpp ping patch
    entity_cpp = os.path.join(openauto_dir, "src/autoapp/Service/AndroidAutoEntity.cpp")
    with open(entity_cpp, "r") as f:
        content = f.read()

    if "#include <chrono>" not in content:
        content = content.replace(
            "#include <f1x/openauto/Common/Log.hpp>",
            "#include <f1x/openauto/Common/Log.hpp>\n#include <chrono>",
            1
        )

    old_ping = """void AndroidAutoEntity::sendPing()
{
    auto promise = aasdk::channel::SendPromise::defer(strand_);
    promise->then([]() {}, std::bind(&AndroidAutoEntity::onChannelError, this->shared_from_this(), std::placeholders::_1));

    aasdk::proto::messages::PingRequest request;
    controlServiceChannel_->sendPingRequest(request, std::move(promise));
}"""
    new_ping = """void AndroidAutoEntity::sendPing()
{
    auto promise = aasdk::channel::SendPromise::defer(strand_);
    promise->then([]() {}, std::bind(&AndroidAutoEntity::onChannelError, this->shared_from_this(), std::placeholders::_1));

    auto timestamp = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::high_resolution_clock::now().time_since_epoch());

    aasdk::proto::messages::PingRequest request;
    request.set_timestamp(timestamp.count());
    controlServiceChannel_->sendPingRequest(request, std::move(promise));
}"""
    if old_ping in content:
        content = content.replace(old_ping, new_ping)

    with open(entity_cpp, "w") as f:
        f.write(content)

    # 3) autoapp.cpp geometry & wireless auto-connect patch
    main_cpp = os.path.join(openauto_dir, "src/autoapp/autoapp.cpp")
    with open(main_cpp, "r") as f:
        content = f.read()

    if "#include <QScreen>" not in content:
        content = content.replace("#include <QApplication>", "#include <QApplication>\n#include <QScreen>", 1)

    if "#include <boost/asio/ip/tcp.hpp>" not in content:
        content = content.replace(
            "#include <f1x/aasdk/TCP/TCPWrapper.hpp>",
            "#include <f1x/aasdk/TCP/TCPWrapper.hpp>\n#include <boost/asio/ip/tcp.hpp>",
            1
        )

    old_mw = """    autoapp::ui::MainWindow mainWindow;
    mainWindow.setWindowFlags(Qt::WindowStaysOnTopHint);"""
    new_mw = """    autoapp::ui::MainWindow mainWindow;
    mainWindow.setWindowFlags(Qt::WindowStaysOnTopHint);
    mainWindow.setGeometry(QGuiApplication::primaryScreen()->geometry());"""
    if old_mw in content:
        content = content.replace(old_mw, new_mw)

    old_show = """    mainWindow.showFullScreen();"""
    new_show = """    mainWindow.hide();"""
    if old_show in content:
        content = content.replace(old_show, new_show)

    old_start = """    QObject::connect(&connectDialog, &autoapp::ui::ConnectDialog::connectionSucceed, [&app](auto socket) {
        app->start(std::move(socket));
    });

    app->waitForUSBDevice();"""
    new_start = """    QObject::connect(&connectDialog, &autoapp::ui::ConnectDialog::connectionSucceed, [&app](auto socket) {
        app->start(std::move(socket));
    });

    // Wireless Android Auto: aa_wireless_handoff.py's WifiStartRequest tells the
    // phone to dial OUT to this head unit's own IP/port over the hotspot Wi-Fi —
    // so the phone is the TCP client and we must be the TCP server here. aasdk's
    // TCPWrapper only supports outbound asyncConnect (that's what the block above
    // uses, for dialing INTO an external wireless dongle on port 5277 — a
    // different architecture), so a raw boost::asio acceptor is used directly.
    static const unsigned short WIRELESS_LISTEN_PORT = 50001;
    auto wirelessAcceptor = std::make_shared<boost::asio::ip::tcp::acceptor>(
        ioService, boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v4(), WIRELESS_LISTEN_PORT));
    auto wirelessSocket = std::make_shared<boost::asio::ip::tcp::socket>(ioService);
    OPENAUTO_LOG(info) << "[autoapp] Listening for wireless Android Auto on port " << WIRELESS_LISTEN_PORT;
    wirelessAcceptor->async_accept(*wirelessSocket, [&app, wirelessAcceptor, wirelessSocket](const boost::system::error_code& ec) {
        if(!ec)
        {
            OPENAUTO_LOG(info) << "[autoapp] Wireless phone connected from " << wirelessSocket->remote_endpoint().address().to_string();
            app->start(std::move(wirelessSocket));
        }
        else
        {
            OPENAUTO_LOG(error) << "[autoapp] Wireless accept failed: " << ec.message();
        }
    });

    app->waitForUSBDevice();"""
    if old_start in content:
        content = content.replace(old_start, new_start)

    with open(main_cpp, "w") as f:
        f.write(content)

    # 4) QtVideoOutput.cpp geometry patch
    video_cpp = os.path.join(openauto_dir, "src/autoapp/Projection/QtVideoOutput.cpp")
    with open(video_cpp, "r") as f:
        content = f.read()

    if "#include <QScreen>" not in content:
        content = content.replace("#include <QApplication>", "#include <QApplication>\n#include <QScreen>", 1)

    old_vw = """    videoWidget_->setAspectRatioMode(Qt::IgnoreAspectRatio);
    videoWidget_->setFocus();
    videoWidget_->setWindowFlags(Qt::WindowStaysOnTopHint);
    videoWidget_->setFullScreen(true);
    videoWidget_->show();"""
    new_vw = """    videoWidget_->setAspectRatioMode(Qt::IgnoreAspectRatio);
    videoWidget_->setFocus();
    videoWidget_->setWindowFlags(Qt::WindowStaysOnTopHint);
    videoWidget_->setGeometry(QGuiApplication::primaryScreen()->geometry());
    videoWidget_->setFullScreen(true);
    videoWidget_->show();"""
    if old_vw in content:
        content = content.replace(old_vw, new_vw)

    with open(video_cpp, "w") as f:
        f.write(content)

    print("OpenAuto custom patches applied successfully!")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "openauto"
    patch_openauto(target)
