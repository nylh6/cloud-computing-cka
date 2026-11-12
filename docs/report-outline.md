# Đề Cương Báo Cáo Giữa Kỳ (Tối đa 10 trang PDF)

Tài liệu khung phục vụ việc xuất file Báo cáo PDF theo đúng yêu cầu đề bài và thang điểm chấm.

---

## Cấu trúc 10 trang báo cáo đề xuất

### Trang 1: Trang bìa
- Tên trường, khoa, môn học: **Điện toán đám mây (Cloud Computing - Khoá CKA 2026)**
- Đề tài: **Triển khai ứng dụng web với Docker và Kubernetes**
- Giảng viên hướng dẫn
- Danh sách nhóm sinh viên (5 thành viên, MSSV, phân công nhiệm vụ)
- Hạn nộp: 19/11/2026

### Trang 2: Kiến trúc hệ thống & Sơ đồ Cluster
- **Sơ đồ kiến trúc tổng quan:**
  - Client Browser -> Frontend Service (NodePort: 30080 / Ingress).
  - Frontend Pod (Nginx reverse proxy) -> Backend Service (ClusterIP: 3000) -> MySQL Service (ClusterIP: 3306).
- **Sơ đồ phân bố Node trong Cluster:**
  - 1 Control Plane (`cp`)
  - 2 Worker Nodes (`worker1`, `worker2`)
  - Bảng thông số cấu hình Cloud VM, IP private, CNI Flannel.

### Trang 3 - 4: Đóng gói ứng dụng bằng Docker
- Giới thiệu công nghệ ứng dụng (NestJS Backend + React Vite Frontend + MySQL).
- Thiết kế multi-stage Dockerfile cho Backend (`apps/api/Dockerfile`).
- Thiết kế multi-stage Dockerfile cho Frontend (`apps/web/Dockerfile`) kèm cấu hình Nginx reverse proxy.
- Ảnh chụp màn hình:
  - Lệnh build image: `nylh6/cloud-backend:v1` và `nylh6/cloud-frontend:v1`.
  - Image trên Docker Hub Registry (thể hiện rõ các tag `v1`, `v2`, không dùng `latest`).

### Trang 5 - 6: Dựng Cluster Kubernetes & Triển khai Ứng dụng
- Các bước khởi tạo cluster với `kubeadm init`, `kubeadm join`.
- Cài đặt CNI Flannel.
- Ảnh chụp màn hình: `kubectl get nodes -o wide` (3 node ở trạng thái `Ready`).
- Khai báo Namespace (`cloud-app`), ConfigMap, Secret, MySQL PVC, Migration Job.
- Thiết kế Deployment:
  - 2 Replicas cho mỗi thành phần.
  - Phân tích cấu hình `podAntiAffinity` để ép Pod phân tán đều trên cả 2 worker node.
- Ảnh chụp màn hình: `kubectl get pods -n cloud-app -o wide` chứng minh Pod nằm trên cả 2 node `worker1` và `worker2`.
- Ảnh chụp màn hình: Truy cập ứng dụng web thành công qua trình duyệt từ IP máy ảo.

### Trang 7 - 8: Vận hành trên Kubernetes
- **Kịch bản 1: Scale Deployment lên 4 replicas:**
  - Lệnh thực thi và ảnh chụp màn hình 4 Pod phân bố đều.
- **Kịch bản 2: Cập nhật image phiên bản mới & Rollback:**
  - Build `v2`, rollout update và kiểm tra `kubectl rollout status`.
  - Thực hiện rollback bằng `kubectl rollout undo` và kiểm tra lịch sử rollback.
- **Kịch bản 3: Thử nghiệm tắt một Worker Node:**
  - Tắt VM `worker2` (hoặc lệnh `kubectl drain worker2`).
  - Phân tích tiến trình: Node chuyển `NotReady` -> K8s phát hiện và eviction -> Tự động khởi tạo lại Pod thay thế trên `worker1`.
  - Ảnh chụp màn hình chứng minh ứng dụng vẫn hoạt động liên tục (High Availability).

### Trang 9: Khó khăn gặp phải & Giải pháp
1. **Vấn đề CORS & Gọi API giữa Frontend và Backend trong K8s:**
   - *Khó khăn:* Frontend chạy trên trình duyệt client, không thể phân giải tên miền service nội bộ của K8s.
   - *Giải pháp:* Sử dụng Nginx trong container Frontend làm reverse proxy chuyển tiếp `/api` sang `backend-service:3000`.
2. **Đảm bảo Pod phân tán đều trên 2 worker node:**
   - *Khó khăn:* Mặc định K8s Scheduler có thể xếp cả 2 replica vào cùng 1 node nếu node đó nhiều tài nguyên hơn.
   - *Giải pháp:* Áp dụng `podAntiAffinity` với `preferredDuringSchedulingIgnoredDuringExecution` theo `kubernetes.io/hostname`.
3. **Thứ tự khởi động giữa Database Migration và Backend:**
   - *Khó khăn:* Backend khởi động trước khi DB chạy xong migration sẽ dẫn đến lỗi crash.
   - *Giải pháp:* Tách migration thành K8s Job có `initContainers` chờ cổng MySQL sẵn sàng trước khi thực thi.

### Trang 10: Kết luận & Tài liệu tham khảo
- Đánh giá mức độ hoàn thành bài tập so với mục tiêu đề bài.
- Link GitHub repository: `https://github.com/nylh6/cloud-computing-cka`
- Tài liệu tham khảo (Kubernetes Official Documentation, Kubeadm guide, Docker docs).
