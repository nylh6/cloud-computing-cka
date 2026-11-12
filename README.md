# Cloud Computing - CKA Midterm Project

Dự án bài tập giữa kỳ môn **Điện toán đám mây (Khoá CKA 2026)**: Triển khai ứng dụng web full-stack với Docker và Kubernetes (1 Control Plane + 2 Worker Nodes).

---

## 1. Công nghệ sử dụng (Tech Stack)

- **Backend:** NestJS (Node.js, TypeScript), TypeORM, JWT Authentication, Health checks.
- **Frontend:** React (Vite, TypeScript, Tailwind CSS, shadcn/ui), TanStack Query, React Hook Form, Zod.
- **Web Server & Reverse Proxy:** Nginx (đóng gói cùng frontend để proxy `/api` sang backend service).
- **Database:** MySQL 8.4 (Persistent Volume Claim, TypeORM migrations).
- **Containerization:** Multi-stage Dockerfiles riêng biệt cho từng thành phần.
- **Orchestration:** Kubernetes (kubeadm, CNI Flannel, Pod Anti-Affinity, NodePort/Ingress).

---

## 2. Cấu trúc thư mục (Project Layout)

```text
cloud-computing-cka/
├── apps/
│   ├── api/                       # NestJS API Backend
│   │   ├── Dockerfile             # Multi-stage Dockerfile cho Backend
│   │   └── src/
│   └── web/                       # React Frontend
│       ├── Dockerfile             # Multi-stage Dockerfile (Vite Build + Nginx)
│       ├── nginx.conf             # Nginx reverse proxy /api sang backend-service
│       └── src/
│
├── k8s/                           # Toàn bộ tài nguyên Kubernetes (Áp dụng theo thứ tự)
│   ├── 00-namespace.yaml          # Namespace riêng: cloud-app
│   ├── 01-configmap-secret.yaml   # ConfigMap & Secret cho DB, JWT, môi trường
│   ├── 02-mysql.yaml              # PVC, Deployment MySQL 8.4 & ClusterIP Service
│   ├── 03-migration-job.yaml      # K8s Job tự động chạy TypeORM database migration
│   ├── 04-backend.yaml            # Backend Deployment (2 replicas + podAntiAffinity) & Service
│   ├── 05-frontend.yaml           # Frontend Deployment (2 replicas + podAntiAffinity) & NodePort
│   └── 06-ingress.yaml            # Cấu hình Ingress (tuỳ chọn nếu dùng Ingress Controller)
│
├── scripts/
│   ├── build-and-push.sh          # Script tự động build & push Docker images v1/v2
│   └── deploy-k8s.sh              # Script tự động apply toàn bộ K8s manifests
│
├── docs/
│   ├── k8s-cluster-setup.md       # Hướng dẫn dựng 3 VM (cp, worker1, worker2) với kubeadm
│   ├── k8s-operations-guide.md    # Hướng dẫn chi tiết scale, update v2, rollback, tắt node
│   └── report-outline.md          # Đề cương chi tiết cho Báo cáo PDF 10 trang
│
├── compose.yaml                   # Chạy kiểm thử nhanh ở môi trường local
└── package.json
```

---

## 3. Đóng gói ứng dụng bằng Docker

Dự án đã tách riêng `Dockerfile` cho từng thành phần:

### Build và đẩy image lên Docker Hub (gắn tag v1, v2 - không dùng latest)

Sử dụng script có sẵn:
```bash
# Build và push phiên bản v1
./scripts/build-and-push.sh nylh6 v1

# Build và push phiên bản v2 (phục vụ kiểm thử cập nhật & rollback)
./scripts/build-and-push.sh nylh6 v2
```

Hoặc thực hiện thủ công bằng lệnh Docker:
```bash
# Backend
docker build -f apps/api/Dockerfile -t nylh6/cloud-backend:v1 .
docker push nylh6/cloud-backend:v1

# Frontend
docker build -f apps/web/Dockerfile -t nylh6/cloud-frontend:v1 .
docker push nylh6/cloud-frontend:v1
```

---

## 4. Dựng Cluster Kubernetes (1 Control Plane + 2 Workers)

Chi tiết từng bước cấu hình máy ảo cloud, cài `kubeadm`, `containerd`, `flannel` xem tại:
👉 [docs/k8s-cluster-setup.md](./docs/k8s-cluster-setup.md)

Xác minh cụm 3 node sẵn sàng:
```bash
kubectl get nodes -o wide
```
*(Yêu cầu: Đủ 3 node `cp`, `worker1`, `worker2` hiển thị trạng thái `Ready`).*

---

## 5. Triển khai ứng dụng lên Kubernetes

### Cách 1: Sử dụng script tự động
```bash
./scripts/deploy-k8s.sh
```

### Cách 2: Áp dụng thủ công từng file YAML
```bash
# 1. Tạo namespace riêng
kubectl apply -f k8s/00-namespace.yaml

# 2. Cấu hình ConfigMap và Secret
kubectl apply -f k8s/01-configmap-secret.yaml

# 3. Triển khai MySQL Database và chờ sẵn sàng
kubectl apply -f k8s/02-mysql.yaml
kubectl rollout status deployment/mysql -n cloud-app

# 4. Chạy migration tạo schema cơ sở dữ liệu
kubectl apply -f k8s/03-migration-job.yaml
kubectl wait --for=condition=complete job/db-migration-job -n cloud-app --timeout=120s

# 5. Triển khai Backend API (2 replicas, pod phân tán 2 worker node)
kubectl apply -f k8s/04-backend.yaml
kubectl rollout status deployment/backend -n cloud-app

# 6. Triển khai Frontend Web (2 replicas, Service NodePort 30080)
kubectl apply -f k8s/05-frontend.yaml
kubectl rollout status deployment/frontend -n cloud-app
```

### Kiểm tra trạng thái ứng dụng:
```bash
kubectl get pods,svc,pvc -n cloud-app -o wide
```

### Truy cập ứng dụng từ trình duyệt:
Mở trình duyệt và truy cập vào IP của bất kỳ worker node nào qua cổng NodePort `30080`:
```text
http://<IP_WORKER1>:30080
hoặc
http://<IP_WORKER2>:30080
```

---

## 6. Vận hành trên Kubernetes

Chi tiết các kịch bản kiểm thử và giải thích cơ chế xem tại:
👉 [docs/k8s-operations-guide.md](./docs/k8s-operations-guide.md)

### 6.1. Scale một Deployment lên 4 replicas
```bash
kubectl scale deployment backend --replicas=4 -n cloud-app
kubectl get pods -n cloud-app -l app=backend -o wide
```

### 6.2. Cập nhật image phiên bản mới (v2) và Rollback về v1
```bash
# Cập nhật lên image v2
kubectl set image deployment/frontend frontend=nylh6/cloud-frontend:v2 -n cloud-app
kubectl rollout status deployment/frontend -n cloud-app

# Hoàn tác (Rollback) về image v1
kubectl rollout undo deployment/frontend -n cloud-app
kubectl rollout status deployment/frontend -n cloud-app
```

### 6.3. Thử nghiệm tắt một worker node
```bash
# Giả lập tắt worker2
kubectl drain worker2 --ignore-daemonsets --delete-emptydir-data

# Quan sát quá trình K8s tự động di chuyển Pod sang worker1
kubectl get pods -n cloud-app -o wide -w
```

---

## 7. Báo cáo và Sản phẩm nộp

- **Mã nguồn & Manifests:** GitHub repository: `https://github.com/nylh6/cloud-computing-cka`
- **Đề cương Báo cáo PDF:** [docs/report-outline.md](./docs/report-outline.md)
