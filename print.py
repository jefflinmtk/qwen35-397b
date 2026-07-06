cmd = """
sudo docker exec -it $(sudo docker ps --filter name=node- --format '{{.Names}}' | head -1) \
    python3 -c "import torch; print(torch.cuda.get_device_capability())"
"""

print(cmd)
