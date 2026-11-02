# Bộ mô tả tạo ảnh: Sky Garden

Mục tiêu: phong cách casual farm game trên mobile, vẽ tay 2.5D, nhiều chi tiết. Đây là hình gốc của LexiFlow: không chép nhân vật, logo hay hình từ game có sẵn, và không đưa tên game khác vào mô tả.

## Quy tắc chung

- Tạo tất cả trong cùng một công cụ. Nếu công cụ hỗ trợ, dùng ảnh đầu tiên được duyệt làm ảnh tham chiếu phong cách.
- Vật thể: PNG nền trong suốt, căn giữa, tối thiểu 1024×1024, chừa lề khoảng 8%, chân vật thể nằm sát đáy vùng vẽ.
- Không có chữ, watermark hay khung.
- Ghi lại công cụ đã dùng và điều khoản sử dụng để trích dẫn trong đồ án.

## Khối phong cách (dán vào đầu mọi mô tả)

> Polished casual mobile farming game asset, hand-painted 2.5D cartoon style, soft rounded chunky shapes, saturated warm colors, soft top-left sunlight, gentle ambient occlusion, glossy highlights, subtle painterly texture, clean silhouette, slight three-quarter view from above, isolated object on transparent background, no text, no watermark, no pixel art.

## Danh sách ảnh

### Cây (18 ảnh): `crop-<id>-<stage>.png`

Sinh theo mẫu: `[khối phong cách] A <cây> plant, <giai đoạn>, growing straight up, no pot, cute and lively.`

| id | Cây (mô tả) |
|---|---|
| corn | corn |
| tomato | tomato |
| flower | pink lily flower |
| apple | small apple tree |
| herbs | bushy green herbs |
| blueberry | blueberry bush |

| stage | Giai đoạn (mô tả) |
|---|---|
| 0 | tiny sprout with two small leaves |
| 1 | half-grown young plant with small unripe fruit or buds |
| 2 | fully grown, abundant, ripe and shiny |

### Chậu (4 ảnh): `pot-0.png` … `pot-3.png`

`[khối phong cách] An empty ornate magical flower pot with visible soil on top, <kiểu>.`

0. sea-dragon scale pattern, turquoise glaze with silver trim
1. phoenix feather pattern, sunset orange glaze with gold trim
2. carved jade green with white trim
3. ancient terracotta with engraved runes

### Khung cảnh

- `cloud-platform.png` (2048×768, trong suốt): `[khối phong cách] A long floating fluffy white cloud platform seen from slightly above, flat walkable top surface, volumetric soft blue shadows underneath, wide horizontal shape.`
- `sky.png` (1920×1080, không trong suốt, bỏ cụm "isolated object on transparent background"): `[khối phong cách] Bright fantasy morning sky background, layered distant clouds, soft sun glow from the top left, calm empty center, no objects, no characters.`
- `beanstalk.png` (768×2048, trong suốt): `[khối phong cách] A giant magical green beanstalk climbing vertically with curling tendrils and big leaves, seamless top and bottom.`
- `cloud-small.png` (trong suốt): `[khối phong cách] A single small fluffy cloud.`

### Đồ vật

- `basket.png`: `A small woven harvest basket full of produce.`
- `coin.png`: `A shiny gold coin with a leaf emblem.`
- `drop.png`: `A glossy cute blue water droplet.`
- `icon-orders.png`: `A rolled parchment order scroll with a wax seal.`
- `icon-study.png`: `An open magical vocabulary book with sparkles.`
- `icon-inventory.png`: `A wooden farm storage crate with produce.`

## Thứ tự làm

1. Tạo `crop-apple-2`, `pot-0`, `cloud-platform` trước để chốt phong cách.
2. Khi đã ưng, tạo phần còn lại dựa trên ba ảnh đó.
3. Đặt toàn bộ vào một thư mục, đúng tên file ở trên.
