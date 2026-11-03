# WORKLOG TUẦN 4 – ĐIỆN TOÁN ĐÁM MÂY

**Đề tài:** Ứng dụng realtime bảng xếp hạng game với DynamoDB Streams  
**Môn học:** Điện toán đám mây – Cloud, Đợt 1 (2026–2027)  
**Ngày báo cáo:** 03/11/2026  
**Môi trường triển khai:** AWS Learner Lab, tài khoản dùng chung, Region `us-east-1`

## 1. Thành viên nhóm

| MSSV | Thành viên | Vai trò |
|---|---|---|
| 24110018 | Cao Gia Huy | Trưởng nhóm |
| 24110035 | Nguyễn Nhân Hiếu Nghĩa | Thành viên |

## 2. Mục tiêu công việc tuần 4

1. Dựng lại toàn bộ hệ thống Leaderboard trên tài khoản AWS Learner Lab mới bằng `deploy.sh`.
2. Chạy benchmark với 1.000 người chơi, 5 vòng ghi điểm; so sánh tải 20 luồng và 50 luồng.
3. Thí nghiệm `batching window` 1 giây và 5 giây, ghi nhận ảnh hưởng đến số lần Lambda được gọi và độ trễ xử lý.
4. Kiểm thử CORS, throttling, chính sách truy cập S3, Event Source Mapping và Reserved Concurrency.
5. Tổng hợp lỗi, giám sát CloudWatch, ước tính chi phí, hoàn thiện báo cáo và dọn tài nguyên AWS.

## 3. Nhật ký công việc theo phân công

> Theo thông tin nhóm xác nhận, cả hai thành viên làm việc trong hai ngày 29/10/2026 (6 giờ/người) và 03/11/2026 (3 giờ/người), tổng cộng 9 giờ/người trong tuần 4. Báo cáo nguồn không chia số giờ theo từng đầu việc và nhóm chưa cung cấp khung giờ bắt đầu/kết thúc hoặc mã commit cụ thể; do đó worklog ghi nhận thời lượng theo ngày, không tự phân bổ giờ hoặc tạo mã commit giả.

### 3.1. Cao Gia Huy – Trưởng nhóm

| Hạng mục | Công việc thực hiện theo báo cáo | Kết quả ghi nhận | Ngày/khung giờ thực tế | Số giờ | Minh chứng / commit |
|---|---|---|---|---:|---|
| Dựng lại hệ thống | Sử dụng `deploy.sh` để tạo lại DynamoDB, Lambda, Event Source Mapping, HTTP API, website S3 và tài nguyên CloudWatch trên tài khoản mới. | TC16 đạt: mapping `Enabled`, API `/top10` trả HTTP 200, website trả HTTP 200. Thời điểm deploy được ghi trong output: `2026-11-03T06:49:31Z`. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng | 
| Benchmark tải | Tổ chức/chạy các đợt giả lập 1.000 người chơi × 5 vòng, với 20 luồng và 50 luồng; kiểm tra kết quả đối chiếu. | Sáu lần chạy lớn đều `MATCH`; thời gian ghi dao động 15,6–145,4 giây. Lần chạy 50 luồng ghi nhận 18,9 giây và `MATCH`. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng | 
| Kiểm thử bảo mật và cấu hình | Kiểm tra CORS với origin hợp lệ/không hợp lệ, throttling, S3 bucket policy, Event Source Mapping và concurrency. | TC08–TC10 đạt; 98/100 request trả HTTP 200 và 2/100 request trả HTTP 429; policy S3 chỉ có `s3:GetObject`; mapping dùng batch 10, retry 3, Bisect bật, window 1 giây và Reserved Concurrency 10. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng | 
| Thu thập minh chứng và cleanup | Chụp minh chứng triển khai/kiểm thử; chạy `cleanup.sh` hai lần và kiểm tra tài nguyên theo tag `Project=Leaderboard`. | TC22 đạt: lần cleanup thứ hai không lỗi; danh sách tài nguyên còn lại theo tag rỗng. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng |

**Tổng số giờ thực tế của Cao Gia Huy:** **9 giờ** (29/10: 6 giờ; 03/11: 3 giờ).  
**Yêu cầu môn học:** tối thiểu 8 giờ/sinh viên/tuần.  
**Trạng thái xác nhận:** Đã ghi nhận theo thời lượng nhóm cung cấp; khung giờ cụ thể và minh chứng/commit vẫn cần bổ sung nếu giảng viên yêu cầu.

### 3.2. Nguyễn Nhân Hiếu Nghĩa

| Hạng mục | Công việc thực hiện theo báo cáo | Kết quả ghi nhận | Ngày/khung giờ thực tế | Số giờ | Minh chứng / commit |
|---|---|---|---|---:|---|
| Thí nghiệm batching window | So sánh cấu hình window 1 giây và 5 giây với cùng tải 1.000 người chơi × 5 vòng, 20 luồng; tổng hợp Invocations, version, xung đột, thời gian Lambda xử lý thêm và Errors. | Window 1 giây: 554 invocations, version 554, 168/256 xung đột, xử lý thêm 6,1 giây, 0 Errors. Window 5 giây: 503 invocations, version 502, 170/250 xung đột, xử lý thêm 11,1 giây, 1 Error. Nhóm không kết luận được lợi ích rõ ràng và giữ window 1 giây. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng |
| Tổng hợp chi phí | Ghi nhận số liệu Learner Lab trước/sau cleanup và tổng hợp ước tính chi phí các request chính. | Learner Lab hiển thị `Used $0 of $50` lúc 14:33 và 14:42 ngày 03/11/2026. Ước tính chi phí request được báo cáo là dưới 0,03 USD; các khoản chưa xác minh được ghi chú riêng. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng | 
| Viết và rà soát báo cáo | Tổng hợp kết quả benchmark, thí nghiệm batching window, chi phí, lỗi/sự cố, hạn chế và hướng phát triển; rà soát nội dung báo cáo tuần 4. | Hoàn thiện nội dung báo cáo tuần 4 và phần worklog; số giờ đã được cập nhật theo xác nhận của nhóm, mã commit/minh chứng cần bổ sung nếu có. | 29/10/2026 (6 giờ) và 03/11/2026 (3 giờ) | Đã tính trong tổng 9 giờ/người; không phân bổ riêng |

**Tổng số giờ thực tế của Nguyễn Nhân Hiếu Nghĩa:** **9 giờ** (29/10: 6 giờ; 03/11: 3 giờ).  
**Yêu cầu môn học:** tối thiểu 8 giờ/sinh viên/tuần.  
**Trạng thái xác nhận:** Đã ghi nhận theo thời lượng nhóm cung cấp; khung giờ cụ thể và minh chứng/commit vẫn cần bổ sung nếu giảng viên yêu cầu.

## 4. Kết quả kỹ thuật chung của tuần 4

### 4.1. Dựng lại hệ thống – TC16

- Tài khoản AWS Learner Lab mới, Region `us-east-1`.
- `deploy.sh` triển khai các nhóm tài nguyên: DynamoDB; Lambda và log retention; Event Source Mapping; HTTP API; website S3; CloudWatch dashboard và alarm.
- Kiểm tra sau triển khai: mapping `Enabled`, API `/top10` trả HTTP 200 và website trả HTTP 200.
- `Reserved Concurrency` của `stream_processor` được đặt là 10; Event Source Mapping có `BatchSize = 10`.

### 4.2. Benchmark tải – TC17 và TC18

Các lần chạy lớn dùng 1.000 người chơi × 5 vòng ghi điểm. Kết quả được ghi trong báo cáo:

| Lần | Số luồng | Thời gian ghi | Lambda xử lý thêm | Version cuối | Kết quả | Ghi chú |
|---:|---:|---:|---:|---:|---|---|
| 1 | 20 | 16,6 giây | 7,1 giây | 505 | MATCH | Window 1 giây |
| 2 | 20 | 145,4 giây | 3,1 giây | 728 | MATCH | Window 1 giây; lần chạy chậm |
| 3 | 20 | 19,0 giây | 4,1 giây | 501 | MATCH | Window 1 giây |
| 4 | 50 | 18,9 giây | 5,1 giây | 505 | MATCH | Window 1 giây |
| 5 | 20 | 47,9 giây | 6,1 giây | 554 | MATCH | Window 1 giây |
| 6 | 20 | 15,6 giây | 11,1 giây | 502 | MATCH | Thí nghiệm window 5 giây |

**Nhận xét:** Cả sáu lần chạy lớn đều `MATCH`. Thời gian ghi chưa ổn định; báo cáo chưa kết luận chắc chắn nguyên nhân của lần chạy chậm 145,4 giây. Không suy rộng kết quả một lần chạy để kết luận 50 luồng nhanh/chậm hơn 20 luồng.

### 4.3. Thí nghiệm batching window

| Chỉ tiêu | Window 1 giây | Window 5 giây |
|---|---:|---:|
| Invocations `stream_processor` | 554 | 503 (304 + 199) |
| Version cuối | 554 | 502 |
| Lần gọi có xung đột / tổng xung đột | 168 / 256 | 170 / 250 |
| Lambda xử lý thêm | 6,1 giây | 11,1 giây |
| Lambda Errors | 0 | 1 |

Window 5 giây giảm số lần gọi khoảng 9%, nhưng thời gian xử lý thêm tăng và có một RuntimeError trong lần đo. Do mỗi cấu hình chỉ có một lần chạy và kết quả chịu biến thiên giữa các lần chạy, nhóm không kết luận được lợi ích rõ ràng; cấu hình cuối được đưa về window 1 giây.

### 4.4. Kiểm thử bảo mật và tổng thể

| Kiểm thử | Kết quả ghi nhận | Trạng thái |
|---|---|---|
| TC08 – CORS origin hợp lệ | HTTP 200 và có `access-control-allow-origin` đúng URL website. | Đạt |
| TC09 – CORS origin lạ | HTTP 200 nhưng không có `access-control-allow-origin`; trình duyệt sẽ chặn origin lạ. | Đạt |
| TC10 – Throttling | 100 request, 30 request song song: 98 HTTP 200 và 2 HTTP 429. | Đạt |
| S3 bucket policy | Chỉ cho phép `s3:GetObject` trên `bucket/*`. | Đạt |
| Mapping / concurrency | Batch 10, Bisect bật, retry 3, window 1 giây, mapping Enabled, Reserved Concurrency 10. | Đạt |
| TC20 – Cùng điểm / điểm giảm | Hai người cùng 9.000 điểm đều vào Top 10; người giảm điểm vẫn còn trong Top 10 và không có người bị đẩy ra quay lại. | Đạt một phần; giới hạn thiết kế đã biết |
| TC21 – Chạy sạch / alarm Errors | Khung 07:10–07:11 UTC có Lambda Errors = 0 và alarm Errors ở trạng thái OK. | Đạt trong khung kiểm tra |
| TC22 – Cleanup hai lần | Lần chạy thứ hai không lỗi; danh sách tài nguyên theo tag rỗng. | Đạt |

### 4.5. Chi phí và cleanup

- Learner Lab hiển thị `Used $0 of $50` tại hai thời điểm 14:33 và 14:42 ngày 03/11/2026.
- Tổng chi phí request được ước tính dưới 0,03 USD theo giả định nêu trong báo cáo; đây không phải số liệu Billing cuối cùng.
- `cleanup.sh` được chạy hai lần liên tiếp; sau cleanup, danh sách tài nguyên theo tag `Project=Leaderboard` rỗng.

## 5. Nhật ký theo ngày/ca làm thực tế – bổ sung trước khi nộp

> Ngày và thời lượng dưới đây do nhóm xác nhận. Báo cáo không cung cấp giờ bắt đầu/kết thúc hoặc phân bổ số giờ đến từng nhiệm vụ, vì vậy không tự suy diễn các chi tiết này.

| Ngày | Thành viên | Giờ bắt đầu – kết thúc | Nội dung công việc thực tế | Thời lượng (giờ) | Link minh chứng / commit |
|---|---|---|---|---:|---|
| 29/10/2026 | Cao Gia Huy | Thực hiện các hạng mục tuần 4 theo phân công: chuẩn bị/triển khai hệ thống, benchmark và kiểm tra kết quả. | 6 | 
| 03/11/2026 | Cao Gia Huy | Tiếp tục kiểm tra hệ thống, kiểm thử bảo mật, thu thập minh chứng và cleanup theo báo cáo tuần 4. | 3 | 
| 29/10/2026 | Nguyễn Nhân Hiếu Nghĩa | Thực hiện các hạng mục tuần 4 theo phân công: theo dõi/thí nghiệm batching window và tổng hợp kết quả. | 6 | 
| 03/11/2026 | Nguyễn Nhân Hiếu Nghĩa | Hoàn thiện so sánh batching window, tổng hợp chi phí, viết và rà soát báo cáo tuần 4. | 3 | 

## 6. Khai báo sử dụng AI

Theo báo cáo tuần 4, nhóm có sử dụng Claude (Anthropic) để gợi ý và viết mã cho script `deploy/cleanup`, code Lambda và `simulate.py`; hỗ trợ hướng dẫn lệnh CLI và tổ chức nội dung báo cáo. Nhóm tự thực hiện thao tác trên AWS và GitHub, tự chụp minh chứng và đối chiếu số liệu. Các thành viên cần điều chỉnh nội dung khai báo này nếu quá trình sử dụng AI thực tế có khác biệt.



