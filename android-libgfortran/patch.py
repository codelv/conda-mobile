
flags = "CARG CLOG CSINH CCOSH CTANH CSIN CCOS CTAN CASIN CACOS CATAN CASINH CACOSH CATANH".split()
config = ['/* Patched */']
found = []
with open('config.h') as f:
    config.extend([line for line in f])
    config.extend(['#define HAVE_{}'.format(flag) for flag in flags])

with open('config.h', 'w') as f:
    f.write('\n'.join(config))
