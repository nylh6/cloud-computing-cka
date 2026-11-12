# BÀI TẬP GIỮA KỲ – KHOÁ CKA 2026
## Triển khai ứng dụng web với Docker và Kubernetes

### Thông tin nhóm
- **Đề tài:** Đóng gói và triển khai ứng dụng web lên Kubernetes cluster (1 Control Plane + 2 Worker Nodes)
- **Hình thức:** Bài tập nhóm (5 sinh viên)
- **Hạn nộp:** 19/11/2026

#### Thành viên nhóm:
1. `[Họ và tên 1]` - `[MSSV]` (Trưởng nhóm)
2. `[Họ và tên 2]` - `[MSSV]`
3. `[Họ và tên 3]` - `[MSSV]`
4. `[Họ và tên 4]` - `[MSSV]`
5. `[Họ và tên 5]` - `[MSSV]`

---

## 1. Giới thiệu ứng dụng web (Mã nguồn cơ sở)

Repository này chứa mã nguồn ứng dụng web quản lý công việc (Task Management) gồm:
- **Backend (`apps/api`):** NestJS (TypeScript), TypeORM, JWT Auth, MySQL.
- **Frontend (`apps/web`):** React (Vite, Tailwind CSS, shadcn/ui).
- **Database:** MySQL 8.4.

### Chạy thử cục bộ với Docker Compose:
```bash
docker compose up -d --build --wait
docker compose exec app node dist/database/seed.js   # Dữ liệu mẫu (nếu cần)
```
Ứng dụng mở tại: `http://localhost:3000`.

---

## 2. Checklist yêu cầu đề bài cho các thành viên

Các thành viên trong nhóm sẽ lần lượt thực hiện và push code/tài liệu lên repository này:

### [ ] Phần 1: Đóng gói ứng dụng bằng Docker (2 điểm)
- [ ] Viết `Dockerfile` riêng cho Backend (`apps/api/`).
- [ ] Viết `Dockerfile` riêng cho Frontend (`apps/web/`).
- [ ] Build và đẩy image lên Docker Hub (gắn tag phiên bản cụ thể như `v1`, `v2`, không dùng `latest`).

### [ ] Phần 2: Dựng cluster Kubernetes (2 điểm)
- [ ] Tạo 3 máy ảo trên cloud: `cp`, `worker1`, `worker2`.
- [ ] Cài Kubernetes bằng `kubeadm`, cài CNI (Flannel/Calico).
- [ ] Chụp ảnh xác nhận `kubectl get nodes` hiển thị đủ 3 node ở trạng thái `Ready`.

### [ ] Phần 3: Triển khai ứng dụng lên Kubernetes (2.5 điểm)
- [ ] Tạo thư mục `k8s/` chứa các file YAML cấu hình.
- [ ] Tạo `Namespace` riêng cho ứng dụng.
- [ ] Cấu hình `Deployment` cho từng thành phần (tối thiểu 2 replicas, Pod phân bố trên cả 2 worker node).
- [ ] Cấu hình `Service` (`NodePort` hoặc `Ingress`) để gọi nhau và truy cập từ trình duyệt.
- [ ] Triển khai toàn bộ bằng lệnh `kubectl apply`.

### [ ] Phần 4: Vận hành trên Kubernetes (1.5 điểm)
- [ ] Scale một Deployment lên 4 replicas.
- [ ] Build image phiên bản mới (`v2`), cập nhật rollout và rollback về bản cũ (`v1`).
- [ ] Tắt một worker node, quan sát và giải thích hiện tượng.

### [ ] Phần 5: Báo cáo & Thuyết trình (2 điểm)
- [ ] Báo cáo PDF (tối đa 10 trang): sơ đồ cluster, các bước thực hiện, ảnh chụp kết quả, khó khăn gặp phải.
- [ ] Chuẩn bị slide và kịch bản thuyết trình 8–10 phút.
