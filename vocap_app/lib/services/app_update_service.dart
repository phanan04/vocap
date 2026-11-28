import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final String htmlUrl;
  final String? error;

  UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    required this.htmlUrl,
    this.error,
  });
}

class AppUpdateService {
  static const String currentVersion = '1.0.1';
  static const String _apiUrl = 'https://api.github.com/repos/phanan04/vocap/releases/latest';

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          releaseName: 'Vocap v$currentVersion',
          releaseNotes: 'Chưa có bản phát hành mới trên GitHub.',
          htmlUrl: 'https://github.com/phanan04/vocap/releases',
        );
      }

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          releaseName: '',
          releaseNotes: '',
          htmlUrl: 'https://github.com/phanan04/vocap/releases',
          error: 'Không thể kiểm tra cập nhật (HTTP ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? 'v$currentVersion').trim();
      final latestVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseName = (data['name'] as String? ?? rawTag).trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();
      final htmlUrl = (data['html_url'] as String? ?? 'https://github.com/phanan04/vocap/releases').trim();

      String? apkUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      final hasUpdate = _isNewerVersion(latestVersion, currentVersion);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkUrl,
        htmlUrl: htmlUrl,
      );
    } catch (e) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseName: '',
        releaseNotes: '',
        htmlUrl: 'https://github.com/phanan04/vocap/releases',
        error: 'Lỗi kết nối khi kiểm tra cập nhật.',
      );
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();

    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
    for (int i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  Future<bool> launchUpdateDownload(String url) async {
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
