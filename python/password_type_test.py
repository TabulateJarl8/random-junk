import time
import getpass

for i in range(3, 0, -1):
	print(i)
	time.sleep(1)

print('go')
now = time.time()
passw = getpass.getpass()
after = time.time()
cps = len(passw) / (after - now)
print(f'CPS: {cps}')
print(f'WPM: {cpm/5*60}')
