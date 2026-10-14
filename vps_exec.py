import paramiko, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

host = "185.98.128.123"
user = "root"
pwd = "vfZeEJTY5Fz"

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(host, username=user, password=pwd, timeout=15, allow_agent=False, look_for_keys=False)

cmds = sys.argv[1] if len(sys.argv) > 1 else "ls /opt/mykog-api"
stdin, stdout, stderr = c.exec_command(cmds, timeout=60)
out = stdout.read().decode("utf-8", "replace")
err = stderr.read().decode("utf-8", "replace")
print(out)
if err:
    print("STDERR:", err[:2000])
c.close()
