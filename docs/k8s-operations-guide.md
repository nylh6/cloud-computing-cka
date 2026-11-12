# Hướng Dẫn Vận Hành Trên Kubernetes & Giải Thích Hiện Tượng

Tài liệu này phục vụ **Yêu cầu 4** của bài tập giữa kỳ: Scale deployment, Cập nhật image mới & Rollback, Thử nghiệm tắt worker node và giải thích chi tiết cơ chế hoạt động của Kubernetes.

---

## 1. Scale một Deployment lên 4 Replicas

### Câu lệnh thực hiện:
```bash
# Scale Deployment backend lên 4 replicas
kubectl scale deployment backend --replicas=4 -n cloud-app

# Hoặc scale Deployment frontend lên 4 replicas
kubectl scale deployment frontend --replicas=4 -n cloud-app
```

### Kiểm tra kết quả:
```bash
kubectl get deployment backend -n cloud-app
kubectl get pods -n cloud-app -l app=backend -o wide
```

### Quan sát & Giải thích:
- Số lượng Pod tăng từ 2 lên 4.
- Do cấu hình `podAntiAffinity` với `topologyKey: kubernetes.io/hostname`, K8s Scheduler sẽ cố gắng phân bố đều: 2 Pod trên `worker1` và 2 Pod trên `worker2`.
- Load balancing thông qua `backend-service` sẽ tự động phân phối tải đều cho cả 4 Pod.

---

## 2. Cập nhật Phiên bản Mới (v2) và Rollback về Phiên bản Cũ (v1)

### Bước 2.1: Chuẩn bị image phiên bản mới (v2)
Bạn có thể sửa nhỏ file `apps/web/src/components/app-logo.tsx` hoặc đổi màu giao diện, sau đó build và push `v2`:
```bash
./scripts/build-and-push.sh nylh6 v2
```

### Bước 2.2: Cập nhật Deployment với image mới
```bash
kubectl set image deployment/frontend frontend=nylh6/cloud-frontend:v2 -n cloud-app

# Theo dõi quá trình Rolling Update
kubectl rollout status deployment/frontend -n cloud-app
```

### Bước 2.3: Kiểm tra lịch sử cập nhật
```bash
kubectl rollout history deployment/frontend -n cloud-app
```

### Bước 2.4: Thực hiện Rollback về phiên bản cũ (v1)
```bash
# Lệnh rollback về bản trước đó
kubectl rollout undo deployment/frontend -n cloud-app

# Theo dõi quá trình hoàn tác
kubectl rollout status deployment/frontend -n cloud-app
```

### Quan sát & Giải thích:
- Kubernetes thực hiện chiến lược `RollingUpdate`: Tạo Pod mới trước, kiểm tra readiness probe, khi Pod mới `Ready` thì mới xoá dần Pod cũ -> Không gây gián đoạn dịch vụ (Zero Downtime).
- Khi lệnh `rollout undo` được thực thi, K8s tự động chuyển ReplicaSet về phiên bản trước (v1) theo cùng cơ chế rolling update an toàn.

---

## 3. Thử nghiệm Tắt một Worker Node & Giải Thích Chi Tiết

### Bước 3.1: Kiểm tra trạng thái các Pod trước khi tắt node
```bash
kubectl get pods -n cloud-app -o wide
```
*(Ghi nhận: Pod 1 đang chạy trên worker1, Pod 2 đang chạy trên worker2).*

### Bước 3.2: Thực hiện tắt worker node
Bạn có 2 cách thực hiện:
- **Cách 1 (Thực tế trên Cloud):** Vào bảng điều khiển Cloud (AWS EC2 / GCP Console) và chọn `Stop Instance` máy ảo `worker2`.
- **Cách 2 (Mô phỏng qua K8s command):**
  ```bash
  kubectl drain worker2 --ignore-daemonsets --delete-emptydir-data
  ```

### Bước 3.3: Quan sát liên tục
```bash
kubectl get nodes -w
kubectl get pods -n cloud-app -o wide -w
```

### Bước 3.4: Giải thích chi tiết điều gì xảy ra với ứng dụng

1. **Giai đoạn phát hiện lỗi (Node Controller & Heartbeat):**
   - Kubelet trên `worker2` gửi heartbeat định kỳ (mặc định mỗi 10 giây qua `NodeStatus` lease).
   - Khi `worker2` bị tắt, Controller Plane không nhận được heartbeat sau thời gian `node-monitor-grace-period` (mặc định 40 giây), trạng thái của `worker2` chuyển thành `NotReady`.

2. **Giai đoạn trục xuất Pod (Pod Eviction):**
   - K8s gắn taint `node.kubernetes.io/unreachable:NoExecute` vào `worker2`.
   - Các Pod của Deployment có toleration mặc định là 300 giây (`tolerationSeconds: 300`). Hết thời gian này (hoặc ngay lập tức nếu dùng `kubectl drain`), Pod trên `worker2` sẽ bị đánh dấu `Terminating`.

3. **Giai đoạn Tái sinh Pod (Self-healing & Rescheduling):**
   - Deployment Controller nhận thấy số lượng Pod khả dụng (1 Pod trên `worker1`) thấp hơn mức khai báo (`replicas: 2`).
   - Scheduler sẽ lên lịch tạo ngay một Pod mới thay thế trên node còn sống duy nhất (`worker1`).
   - Do có `preferredDuringSchedulingIgnoredDuringExecution` (thay vì `required`), Scheduler linh hoạt cho phép cả 2 Pod cùng chạy trên `worker1` để đảm bảo tính sẵn sàng cao (High Availability).

4. **Trải nghiệm người dùng:**
   - Người dùng truy cập qua Service NodePort / Ingress vẫn dùng được bình thường, không bị sập ứng dụng nhờ có ít nhất 1 Pod sống sót tiếp nhận lưu lượng.
