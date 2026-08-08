import 'dart:io';

class SystemInfoData {
  final String osVersion;
  final String kernelVersion;
  final String hardwareModel;
  final String cpuArchitecture;
  final String totalRam;
  final String dartVersion;

  const SystemInfoData({
    required this.osVersion,
    required this.kernelVersion,
    required this.hardwareModel,
    required this.cpuArchitecture,
    required this.totalRam,
    required this.dartVersion,
  });
}

class SystemInfoService {
  static Future<SystemInfoData> getRealSystemInfo() async {
    String kernel = Platform.operatingSystemVersion;
    String model = "${Platform.operatingSystem.toUpperCase()} Host Receiver";
    String cpu = "${Platform.numberOfProcessors} CPU Cores (${Platform.operatingSystem})";
    String ram = "System RAM Available";

    if (Platform.isLinux) {
      // 1. Read real Raspberry Pi model name from /proc/device-tree/model
      try {
        final modelFile = File('/proc/device-tree/model');
        if (await modelFile.exists()) {
          final content = (await modelFile.readAsString()).replaceAll('\u0000', '').trim();
          if (content.isNotEmpty) {
            model = content;
          }
        }
      } catch (_) {}

      // 2. Read Linux kernel version via uname -sr
      try {
        final unameResult = await Process.run('uname', ['-sr']);
        if (unameResult.exitCode == 0 && unameResult.stdout.toString().trim().isNotEmpty) {
          kernel = unameResult.stdout.toString().trim();
        }
      } catch (_) {}

      // 3. Read CPU architecture via uname -m
      try {
        final archResult = await Process.run('uname', ['-m']);
        if (archResult.exitCode == 0 && archResult.stdout.toString().trim().isNotEmpty) {
          final arch = archResult.stdout.toString().trim();
          cpu = "$arch • ${Platform.numberOfProcessors} CPU Cores";
        }
      } catch (_) {}

      // 4. Read RAM memory total from /proc/meminfo
      try {
        final memFile = File('/proc/meminfo');
        if (await memFile.exists()) {
          final lines = await memFile.readAsLines();
          for (var l in lines) {
            if (l.startsWith('MemTotal:')) {
              final kb = int.tryParse(RegExp(r'\d+').stringMatch(l) ?? '') ?? 0;
              if (kb > 0) {
                final gb = (kb / (1024 * 1024)).toStringAsFixed(1);
                ram = "$gb GB RAM (${(kb / 1024).round()} MB Total)";
              }
              break;
            }
          }
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      model = "Windows x64 Host System";
    } else if (Platform.isMacOS) {
      model = "macOS Host System";
    }

    final dartVer = Platform.version.split(' ').first;
    final osVersionStr = await getAppVersionString();

    return SystemInfoData(
      osVersion: osVersionStr,
      kernelVersion: kernel,
      hardwareModel: model,
      cpuArchitecture: cpu,
      totalRam: ram,
      dartVersion: "Dart $dartVer",
    );
  }

  static Future<String> getAppVersionString() async {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (await pubspecFile.exists()) {
        final lines = await pubspecFile.readAsLines();
        for (var line in lines) {
          if (line.trim().startsWith('version:')) {
            final ver = line.split(':').last.trim(); // e.g. "1.0.0+1"
            final parts = ver.split('+');
            if (parts.length == 2) {
              return "HeadUnit OS v${parts[0]} (Build ${parts[1]})";
            }
            return "HeadUnit OS v$ver";
          }
        }
      }
    } catch (_) {}
    return "HeadUnit OS v1.0.0 (Build 1)";
  }
}
