import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:PASSTIME/widgets/app_bar.dart';
import 'package:PASSTIME/admin/ticket_edit.dart';
import 'package:PASSTIME/admin/ticket_produce.dart';
import 'package:PASSTIME/admin/request_refund_list.dart';
import 'package:PASSTIME/admin/send_payment_list.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';

class AdminTicketScreen extends StatefulWidget {
  const AdminTicketScreen({super.key});

  @override
  State<AdminTicketScreen> createState() => _AdminTicketScreenState();
}

class _AdminTicketScreenState extends State<AdminTicketScreen> {
  List<Map<String, dynamic>> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/ticket/List');
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      // HTTP 요청
      final response = await http.get(
        url,
        headers: {
          'Cookie': cookieHeader, // 쿠키 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['isSuccess'] == true) {
          final List<dynamic> result = data['result'];

          setState(() {
            tickets = result.map((item) {
              return {
                'ticketId': item['_id'],
                'title': item['eventTitle'],
                'dateTime':
                    '${item['eventDay']} / ${item['eventStartTime'].toString().substring(0, 5)}',
                'location': item['eventPlace'],
                'status': '수정',
                'status2': '삭제',
                'statusColor': const Color(0xFF282727),
                'statusColor2': const Color(0xFFDE4244),
              };
            }).toList();
            isLoading = false; // 데이터 로딩 완료 후 상태 갱신
          });
        } else {
          showErrorSnackbar('데이터를 불러오는데 실패했습니다.');
        }
      } else {
        showErrorSnackbar('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackbar('에러 발생: $e');
    }
  }

  // 에러 메시지를 보여주는 함수
  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      isLoading = false; // 에러 발생 시 로딩 종료
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "행사 관리",
        backgroundColor: Color(0xFF282727),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : tickets.isEmpty
              ? const Center(
                  child: Text(
                    '현재 발급된 입장권이 없습니다',
                    style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
                  ),
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketEditScreen(
                                ticketId: ticket['ticketId'],
                              ),
                            ),
                          );
                          if (result == 'modified') {
                            fetchTickets(); // 수정 후 데이터 새로고침
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket['title']!,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis, // 너무 길면 ... 표시
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 65,
                                    height: 29,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ticket['statusColor'],
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        ticket['status']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 65,
                                    height: 29,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("정말 삭제하시겠습니까?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("취소"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text("삭제"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;

                                        final url = Uri.parse(
                                            '${dotenv.env['API_BASE_URL']}/ticket/delete');

                                        try {
                                          final response = await http.put(
                                            url,
                                            headers: {
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: json.encode({
                                              'ticketId': ticket['ticketId']
                                            }),
                                          );

                                          final data =
                                              json.decode(response.body);
                                          if (data['isSuccess'] == true) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      data['message'] ??
                                                          '삭제되었습니다.')),
                                            );
                                            fetchTickets(); // 삭제 후 목록 갱신
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      data['message'] ??
                                                          '삭제 실패')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('에러 발생: $e')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ticket['statusColor2'],
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        ticket['status2']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("시간  ${ticket['dateTime']}",
                                  style: const TextStyle(fontSize: 14)),
                              Text("장소  ${ticket['location']}",
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('행사 제작'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TicketProduceScreen()),
                      );
                      if (result == 'produced') {
                        fetchTickets(); // 행사 제작 후 새로고침
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('환불 신청 목록'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestRefundListScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('납부 내역 목록'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SendPaymentListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFF282727),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
