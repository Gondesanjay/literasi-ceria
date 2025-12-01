import 'package:flutter/material.dart';

class LogDetailPage extends StatelessWidget {
  final Map<String, dynamic> logData;
  final String contentName;

  const LogDetailPage({
    super.key,
    required this.logData,
    required this.contentName,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil data standar
    final int durasi = logData['durasi'] ?? 0;

    // AMBIL DATA BARU (Fase 4)
    final String module = logData['module'] ?? '-';
    final String result = logData['result'] ?? '-';
    final String detail = logData['detail'] ?? 'Tidak ada catatan detail.';

    // Format Tanggal
    final String createdAtString = logData['createdAt'] ?? '';
    String formattedDate = '-';
    if (createdAtString.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtString).toLocal();
        formattedDate =
            "${dt.day}/${dt.month}/${dt.year} jam ${dt.hour}:${dt.minute}";
      } catch (_) {}
    }

    // Tentukan warna status
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    if (result.toLowerCase() == 'sukses') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (result.toLowerCase() == 'gagal') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // KARTU HEADER (JUDUL)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.videogame_asset,
                      size: 40,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            module,
                            style: TextStyle(color: Colors.indigo.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // KARTU STATUS (HASIL)
            Card(
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(statusIcon, size: 40, color: statusColor),
                title: Text(
                  result.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
                subtitle: const Text("Hasil Aktivitas"),
              ),
            ),

            const SizedBox(height: 10),

            // KARTU DETAIL
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notes, color: Colors.blue),
                    title: const Text("Catatan Detail"),
                    subtitle: Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.orange),
                    title: const Text("Durasi Pengerjaan"),
                    subtitle: Text("$durasi detik"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                    ),
                    title: const Text("Waktu Akses"),
                    subtitle: Text(formattedDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
