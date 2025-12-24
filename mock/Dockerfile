FROM ghcr.io/adriansuarez/noop-provisioner:latest AS builder

FROM alpine:latest

COPY --from=builder /noop-provisioner /bin/noop-provisioner

ENTRYPOINT ["sh"]
