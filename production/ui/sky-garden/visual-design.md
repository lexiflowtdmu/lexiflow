# Thiết kế hình ảnh: Sky Garden

**Ý tưởng:** buổi sáng trên tầng mây, như một món đồ chơi bằng đất sét được chiếu sáng từ phía trên bên trái. Mọi vật có khối và bóng đổ, không dùng emoji cho vật thể chính.

## Màu

| Token | Giá trị | Dùng cho |
|---|---|---|
| sky-top / mid / low | `#0369A1` / `#38BDF8` / `#E0F2FE` | Nền trời |
| cloud / cloud-shade | `#FFFFFF` / `#BAE6FD` | Bệ mây |
| ink | `#0C2D48` | Chữ trên nền sáng |
| panel | `#0C2D48` độ mờ 82% | Nền HUD và dải gợi ý, chữ trắng |
| leaf / leaf-dark | `#22C55E` / `#15803D` | Thân, lá |
| gold | `#FACC15` | Xu, trạng thái chín |
| water | `#38BDF8` | Tiến độ |

Không đặt chữ trực tiếp lên nền trời: luôn đặt trên `panel` hoặc bệ trắng.

## Chữ

Dùng font sẵn có: Outfit cho tiêu đề và số, Plus Jakarta Sans cho nội dung. Cỡ tối thiểu 12 px.

## Minh họa

Không cần tải thêm asset. Tất cả vẽ bằng code, cùng một bộ hình cho hai nền tảng:

- **6 loại cây:** ngô, cà chua, hoa, táo, thảo mộc, việt quất. Mỗi cây có 3 mức lớn: mầm (dưới 34%), đang lớn (dưới 100%), chín.
- **4 chậu:** Rồng Biển, Phượng Hoàng, Ngọc Bích, Đất Nung; có viền miệng, thân gradient, điểm sáng.
- **Bệ mây:** 3 lớp gồm bóng, thân và điểm sáng trên đỉnh.
- **Nền:** 2 lớp mây xa trôi chậm, dây đậu thần có lá.
- **Giữ ở mức trang trí:** chong chóng, ô dù, ốc sên, bọ cam. Không bấm được và ẩn với trình đọc màn hình.

## Chuyển động

| Tên | Thời lượng | Dùng cho |
|---|---|---|
| Đung đưa | 3,2 s, lặp | Cây đang lớn, lệch pha theo ô |
| Nhún | 1,1 s, lặp | Giỏ trên cây chín |
| Bật thu hoạch | 0,4 s | Khi thu hoạch |
| "+N" bay lên | 1,4 s | Sau thu hoạch |
| Mây trôi | 40–70 s, lặp | Nền |

Khi bật giảm chuyển động: tắt mọi vòng lặp, thay đổi trạng thái diễn ra ngay.

## Bố cục phản hồi

- **Web:** khung vườn tối đa 1040 px, 4 chậu mỗi tầng, chậu lớn dần theo chiều rộng.
- **Mobile, từ 320 px:** vẫn 4 chậu mỗi tầng, dây đậu thu còn 32 px, ẩn ốc sên và bọ cam nếu thiếu chỗ.

## Asset

Không có file ngoài. Web dùng SVG nội tuyến, Flutter dùng `CustomPainter`.
