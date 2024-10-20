# SFTP Container

Container for managing data over sftp server.

## Add user public key

There are two ways to setup public key

1. Set variable(s) SSH_CLIENT_someusername="ssh-ed25519 AAAAC3..." and /entrypoint will put it in user home authorized_keys for you
2. Mount authorized_keys directly to user home `/var/www/`

## Connect to sftp server

Container uses precreated user `www-data` with chrooted home under `/var/www/` directory. Directory is owned by root to be able to use ChrootDirectory sshd directive so you are not allowed to write anything directly in this directory.

See [`docker-compose.yaml`](./docker-compose.yaml) `sftp-test` service in case you struggle with connection.

## Deploy to k8s using Argo CD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app-sftp
  namespace: argo-cd-system
spec:
  project: app
  source:
    repoURL: 'https://github.com/Container-Driven-Development/sftp'
    targetRevision: v4.1
    path: k8s
    helm:
      releaseName: test
      values: |
        extraEnv:
          - name: SSHD_ENABLE_SSH # Enable for ssh access
            value: "false"
          - name: SSH_CLIENT_someusername # Add user public key
            value: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAA...

        volumes:
        - name: uploads
          persistentVolumeClaim:
            claimName: test-app-uploads

        volumeMounts:
        - name: uploads
          mountPath: /var/www/bitnami/wordpress/wp-content/uploads

  destination:
    server: https://kubernetes.default.svc
    namespace: test-app
  syncPolicy:
    automated:
      prune: true
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true

