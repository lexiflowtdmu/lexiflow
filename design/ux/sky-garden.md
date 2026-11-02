# UX Spec: Khu Vườn Trên Mây (Sky Garden)

> **Template**: UX Spec
> **Status**: Draft, chờ duyệt
> **Platform Target**: Web dashboard (React), Flutter mobile
> **Input**: Chuột + bàn phím (web), cảm ứng (mobile). Không hỗ trợ gamepad.
> **Accessibility tier**: Giả định WCAG 2.1 AA, chưa được cam kết chính thức.

## 1. Nhu cầu người chơi

"Tôi vừa học xong, tôi muốn thấy việc học của mình làm khu vườn lớn lên, và biết ngay nên làm gì tiếp."

Màn hình phải trả lời ba câu trong vài giây: cây nào thu hoạch được, đơn nào giao được, còn bao nhiêu từ nữa thì cây chín.

## 2. Bối cảnh khi đến

- Thường đến ngay sau phiên học, hoặc từ menu chính.
- Phiên ngắn, khoảng dưới 1 phút. Đây là phần thưởng, không phải nơi học.

## 3. Điều hướng

| Vào từ | Thoát đến |
|---|---|
| Sidebar mục Farm (web), nút Farm trên dashboard (Flutter) | Flashcard, Quiz (từ gợi ý tưới), màn trước đó |

## 4. Bố cục

1. **HUD trên cùng:** tên màn hình, xu, "còn N từ", làm mới.
2. **Dải gợi ý hành động:** một câu duy nhất theo thứ tự ưu tiên ở mục 6.
3. **Vườn:** Tầng Thần Thoại (ô 4–7) ở trên, Tầng Bồng Bềnh (ô 0–3) ở dưới.
4. **Menu:** Đơn hàng (có số đơn giao được), Kho.

| Thành phần | Dữ liệu | Hành động |
|---|---|---|
| Chậu | Cây, giai đoạn, tiến độ | Gieo / xem tiến độ / thu hoạch |
| Thẻ đơn | Vật phẩm có/cần, xu, XP | Giao |
| Ô kho | Cây, số lượng | Chỉ xem |
| Bảng gieo | `crop_catalog`, số từ cần | Chọn cây |

## 5. Trạng thái

| Trạng thái | Cách hiển thị |
|---|---|
| Đang tải | Khung vườn với chậu mờ, không nhảy bố cục |
| Lỗi tải | Thông báo và nút "Thử lại" |
| Người mới, vườn trống | Gợi ý "Bấm một chậu để gieo hạt đầu tiên" |
| Chậu trống / đang lớn / chín | Dấu +  / cây và thanh tiến độ kèm số / cây, giỏ và nhãn "Chín" |
| Đang xử lý | Chậu hoặc nút hiện vòng xoay, chặn bấm lặp |
| Thao tác lỗi | Thông báo, giữ nguyên trạng thái, không cập nhật lạc quan |

Trạng thái không chỉ phân biệt bằng màu: luôn có hình hoặc chữ đi kèm.

## 6. Dải gợi ý (ưu tiên từ trên xuống)

1. Có cây chín: "N cây đã chín, bấm để thu hoạch".
2. Có đơn giao được: "Có N đơn giao được" (bấm mở Đơn hàng).
3. Có chậu trống và chưa có cây đang lớn: "Bấm một chậu để gieo hạt".
4. Có cây đang lớn: "Học thêm N từ để cây chín" (bấm mở Flashcard trên web, quay lại dashboard trên Flutter).
5. Còn lại: "Gieo thêm cây để nhận đơn mới".

## 7. Tương tác

| Hành động | Web | Mobile | Phản hồi |
|---|---|---|---|
| Chạm chậu | Click, Tab + Enter/Space | Tap | Theo trạng thái chậu |
| Thu hoạch | Như trên | Tap, rung nhẹ | Cây bật lên, hiện "+N" |
| Giao đơn | Nút "Giao" | Nút "Giao" | Thông báo xu + XP |
| Đóng bảng | Esc, nút X, bấm nền | Vuốt xuống, bấm nền | Trả focus về nút đã mở (web) |

- Vùng chạm tối thiểu 44×44.
- Tiến độ chỉ đổi khi học thật; không có nút tưới thủ công.

## 8. Không hiển thị

Level 50, kim cương, năng lượng, điểm danh, Phù Thủy và Cửa hàng không xuất hiện cho đến khi có dữ liệu và logic thật ở server. Thu hoạch chỉ báo nông sản; xu và XP chỉ báo khi giao đơn.

## 9. Tiêu chí nghiệm thu

- [ ] Web và Flutter có cùng bố cục, thuật ngữ, thứ tự gợi ý.
- [ ] Không có số liệu giả trên màn hình.
- [ ] Hoàn thành được vòng gieo → học → thu hoạch → giao đơn trên cả hai nền tảng.
- [ ] Web dùng được hoàn toàn bằng bàn phím, Esc đóng bảng.
- [ ] Không tràn ngang ở chiều rộng 320 px; vẫn cân đối ở 1600 px.
- [ ] Tắt hoạt ảnh khi người dùng bật giảm chuyển động.
- [ ] Chữ đạt tỷ lệ tương phản 4.5:1.

## 10. Sai lệch so với chuẩn của Game Studios

- Chuỗi tiếng Việt viết trực tiếp vì dự án chưa có hệ thống đa ngôn ngữ cho màn này.
- Không có âm thanh và không có gamepad.
- Spec này không xử lý các lỗi server: `farm.ts` vẫn tin số giọt từ client và bỏ giọt dư.
