# Kế hoạch tuần 3 (19/10 – 23/10/2026): Tích hợp, bảo mật, giám sát, tự động hóa

## Mục tiêu
1. Chạy lại toàn luồng ổn định và đo số liệu đáng tin cậy.
2. Bảo mật cơ bản cho API và S3.
3. Giám sát bằng CloudWatch (dashboard, alarm).
4. Tự động hóa dựng và dọn tài nguyên bằng script CLI.

## Phân công (mỗi thành viên ≥ 8 giờ)

| Ngày | Thành viên | Công việc | Minh chứng |
|---|---|---|---|
| 19/10 | Cao Gia Huy | Thêm log khi gặp ConditionalCheckFailed trong stream_processor; đặt log retention cho 2 Lambda | Code mới trên GitHub, log có dòng xung đột |
| 19/10 | Nguyễn Nhân Hiếu Nghĩa | Cập nhật sơ đồ kiến trúc theo hệ thống thật (API, web, S3); soạn khung báo cáo tuần 3 | Sơ đồ mới trong docs/ |
| 20/10 | Cao Gia Huy | Chạy simulator 3 lần, ghi thời gian và số xung đột mỗi lần; thử 20 và 50 luồng; tìm nguyên nhân lần chạy chậm | Bảng số liệu thật, ảnh có Account ID, Region, giờ |
| 20/10 | Nguyễn Nhân Hiếu Nghĩa | Viết kịch bản kiểm thử tích hợp (TC08 trở đi) và bảng lỗi mới | Bảng test case |
| 21/10 | Cao Gia Huy | Giới hạn throttling của API; thu hẹp CORS khỏi dấu *; rà lại S3 policy chỉ s3:GetObject | Ảnh cấu hình trước và sau, lệnh curl kiểm tra |
| 21/10 | Nguyễn Nhân Hiếu Nghĩa | Viết chương bảo mật: rủi ro, cách giảm, hạn chế do chỉ dùng LabRole | Chương bảo mật |
| 22/10 | Cao Gia Huy | Tạo CloudWatch dashboard (Invocations, Errors, Throttles, Duration, ConcurrentExecutions) và alarm cho Errors, Throttles | Ảnh dashboard lúc simulator chạy, ảnh alarm |
| 22/10 | Nguyễn Nhân Hiếu Nghĩa | Viết chương giám sát, giải thích từng chỉ số | Chương giám sát |
| 23/10 | Cao Gia Huy | Viết deploy.sh và cleanup.sh (có gắn tag), thử xóa rồi dựng lại từ đầu | Hai script trên GitHub, ảnh chạy thành công |
| 23/10 | Nguyễn Nhân Hiếu Nghĩa | Chạy deploy.sh trên tài khoản Learner Lab của Nghĩa (tag Owner=HieuNghia) | Ảnh chạy trên tài khoản của Nghĩa |
| 23/10 | Cả hai | Rà soát chéo báo cáo, đưa ảnh lên docs/images, cập nhật worklog, dọn tài nguyên | Báo cáo tuần 3 hoàn chỉnh |

## Ràng buộc cần nhớ
- Chỉ dùng Region us-east-1 và LabRole; gắn tag Project/Owner cho mọi tài nguyên mới.
- Dừng hoặc xóa tài nguyên sau mỗi buổi làm; báo cáo chi phí đã dùng cuối kỳ.
- Mỗi minh chứng phải là ảnh thấy Account ID, Region, thời gian.
- Có thể gặp AccessDenied do giới hạn Learner Lab; ghi nguyên lỗi vào bảng lỗi.

## Rủi ro và cách xử lý
- Reset Lab làm mất tài nguyên: lưu toàn bộ code và script lên GitHub trước.
- Lần chạy simulator chậm bất thường: chạy lặp lại và so sánh để xác định nguyên nhân.
- Hạn chế thiết kế (chỉ lưu top 10, không xử lý điểm giảm): ghi rõ trong báo cáo, không sửa nếu không đủ thời gian.
