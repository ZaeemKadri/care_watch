import 'dart:io';

import 'package:care_watch/widgets/common_app_bar.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController otpController = TextEditingController();

  String generatedOtp = "483921"; // mock OTP
  double? _freeSpaceGb;
  double? _totalSpaceGb;
  int? _cacheBytes;
  bool _isRefreshing = false;
  bool _isClearing = false;
  String? _storageError;
  String? _cacheError;

  @override
  void initState() {
    super.initState();
    _refreshStorageAndCache();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> _refreshStorageAndCache() async {
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
      _storageError = null;
      _cacheError = null;
    });

    try {
      final freeSpace = await DiskSpacePlus.getFreeDiskSpace;
      final totalSpace = await DiskSpacePlus.getTotalDiskSpace;

      if (freeSpace == null || totalSpace == null) {
        _storageError = "Storage info unavailable";
      } else {
        _freeSpaceGb = freeSpace;
        _totalSpaceGb = totalSpace;
      }
    } catch (_) {
      _storageError = "Storage info unavailable";
    }

    try {
      final cacheDir = await getApplicationCacheDirectory();
      final cacheSize = await _directorySize(cacheDir);
      _cacheBytes = cacheSize;
    } catch (_) {
      _cacheError = "Cache size unavailable";
    }

    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<int> _directorySize(Directory directory) async {
    var totalSize = 0;
    if (!await directory.exists()) {
      return totalSize;
    }

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearing = true;
    });

    try {
      final cacheDir = await getApplicationCacheDirectory();
      await for (final entity in cacheDir.list(followLinks: false)) {
        await entity.delete(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("App cache cleared")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to clear cache")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isClearing = false;
      });
      await _refreshStorageAndCache();
    }
  }

  Future<void> _copyOtp() async {
    await Clipboard.setData(ClipboardData(text: generatedOtp));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP copied to clipboard")),
    );
  }

  String _formatStorageValue(double? value) {
    if (_storageError != null || value == null) {
      return "Unavailable";
    }

    return "${value.toStringAsFixed(1)} GB";
  }

  String _formatCacheValue() {
    if (_cacheError != null || _cacheBytes == null) {
      return "Unavailable";
    }

    return _formatBytes(_cacheBytes!);
  }

  String _formatBytes(int bytes) {
    const kilo = 1024;
    const mega = kilo * 1024;
    const giga = mega * 1024;

    if (bytes >= giga) {
      return "${(bytes / giga).toStringAsFixed(2)} GB";
    }
    if (bytes >= mega) {
      return "${(bytes / mega).toStringAsFixed(1)} MB";
    }
    if (bytes >= kilo) {
      return "${(bytes / kilo).toStringAsFixed(1)} KB";
    }

    return "${bytes} B";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "CareWatch"),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Secure Connect",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Share this OTP to connect another device",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2F7BFF), Color(0xFF5AA7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                "YOUR OTP",
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _copyOtp,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text("Copy"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            generatedOtp,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Enter OTP",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter 6-digit OTP",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle OTP verification
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F7BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Connect Device",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Device Storage",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storage, color: Color(0xFF2F7BFF)),
                              const SizedBox(width: 8),
                              const Text(
                                "Storage Overview",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_isRefreshing)
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetric(
                                  label: "Free",
                                  value: _formatStorageValue(_freeSpaceGb),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetric(
                                  label: "Total",
                                  value: _formatStorageValue(_totalSpaceGb),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMetric(
                            label: "App cache",
                            value: _formatCacheValue(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "App cache only",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isRefreshing ? null : _refreshStorageAndCache,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Refresh"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isClearing ? null : _clearCache,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2F7BFF),
                                  ),
                                  icon: _isClearing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.cleaning_services),
                                  label: Text(_isClearing ? "Clearing" : "Clear cache"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "End-to-end encrypted connection",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}