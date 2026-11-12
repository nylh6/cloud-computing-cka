# Hướng Dẫn Cài Đặt Kubernetes Cluster (1 Control Plane + 2 Worker Nodes)

Tài liệu này phục vụ **Yêu cầu 2** của bài tập giữa kỳ CKA: Dựng cluster Kubernetes gồm 1 control plane (`cp`) và 2 worker node (`worker1`, `worker2`) trên Cloud, sử dụng `kubeadm` và plugin mạng CNI.

---

## 1. Chuẩn bị 3 máy ảo (VM) trên Cloud

Khởi tạo 3 máy ảo Ubuntu 22.04 LTS (trên AWS EC2, GCP Compute Engine, Azure, hoặc DigitalOcean):

| Node Name | Role | Cấu hình đề xuất | IP Private |
| :--- | :--- | :--- | :--- |
| `cp` | Control Plane | 2 vCPU, 4GB RAM, 20GB Disk | `10.0.0.10` |
| `worker1` | Worker Node | 2 vCPU, 4GB RAM, 20GB Disk | `10.0.0.11` |
| `worker2` | Worker Node | 2 vCPU, 4GB RAM, 20GB Disk | `10.0.0.12` |

### Mở Security Group / Firewall
- **Control Plane (`cp`)**: Mở port `6443` (Kubernetes API server), `2379-2380` (etcd), `10250` (kubelet), `10259`, `10257`.
- **Worker Nodes (`worker1`, `worker2`)**: Mở port `10250` (kubelet), `30000-32767` (NodePort Services - đặc biệt là port `30080` cho frontend).
- **Tất cả các node**: Cho phép lưu lượng nội bộ giữa các node cho CNI (Calico/Flannel dùng port UDP 8472 / IP-in-IP protocol 4).

---

## 2. Cài đặt trên cả 3 Node (`cp`, `worker1`, `worker2`)

Chạy các lệnh sau trên **toàn bộ 3 node**:

### 2.1. Đổi hostname tương ứng
```bash
# Trên máy cp:
sudo hostnamectl set-hostname cp

# Trên máy worker1:
sudo hostnamectl set-hostname worker1

# Trên máy worker2:
sudo hostnamectl set-hostname worker2
```

Cập nhật `/etc/hosts` trên cả 3 máy:
```bash
sudo cat <<EOF | sudo tee -a /etc/hosts
10.0.0.10 cp
10.0.0.11 worker1
10.0.0.12 worker2
EOF
```

### 2.2. Tắt Swap và cấu hình Kernel modules
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 2.3. Cài đặt Container Runtime (`containerd`)
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Cài đặt containerd
sudo apt-get install -y containerd

# Cấu hình containerd systemd cgroup
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 2.4. Cài đặt `kubeadm`, `kubelet`, `kubectl`
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Thêm khóa ký và repository chính thức của Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 3. Khởi tạo Control Plane (Chỉ chạy trên `cp`)

```bash
# Khởi tạo cluster với dải IP Pod tiêu chuẩn cho Flannel/Calico
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.0.0.10

# Cấu hình kubectl cho user không phải root
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3.1. Cài đặt CNI Plugin (Flannel)
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Lệnh `kubeadm init` ở trên sẽ in ra một lệnh `kubeadm join` có kèm token, ví dụ:
```bash
kubeadm join 10.0.0.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## 4. Tham gia Cluster (Chạy trên `worker1` và `worker2`)

Copy lệnh `kubeadm join` vừa nhận được và chạy với quyền `sudo`:
```bash
sudo kubeadm join 10.0.0.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## 5. Xác minh Cluster (Chạy trên `cp`)

Kiểm tra trạng thái các node:
```bash
kubectl get nodes -o wide
```

**Kết quả mong đợi:**
```text
NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP   OS-IMAGE             KERNEL-VERSION
cp        Ready    control-plane   10m   v1.30.x   10.0.0.10     Ubuntu 22.04 LTS     ...
worker1   Ready    <none>          5m    v1.30.x   10.0.0.11     Ubuntu 22.04 LTS     ...
worker2   Ready    <none>          5m    v1.30.x   10.0.0.12     Ubuntu 22.04 LTS     ...
```

Đủ 3 node đều ở trạng thái `Ready` -> Hoàn thành 100% Yêu cầu 2!
