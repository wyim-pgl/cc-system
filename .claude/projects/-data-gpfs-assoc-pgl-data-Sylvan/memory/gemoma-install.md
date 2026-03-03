# GeMoMa 1.9 Installation Record

## Date: 2026-02-24

## Installation Steps

### 1. micromamba 환경 생성
```bash
micromamba create -n gemoma -c bioconda -c conda-forge gemoma -y
```
- bioconda 최신 = 1.7.1 (104 packages installed)
- Java 11, mmseqs2, blast, perl 등 의존성 자동 설치

### 2. GeMoMa 1.9 수동 업그레이드
```bash
# JAR 다운로드
wget -O /tmp/GeMoMa.zip "http://www.jstacs.de/download.php?which=GeMoMa"

# JAR 추출
unzip -o /tmp/GeMoMa.zip GeMoMa-1.9.jar \
  -d /data/gpfs/assoc/pgl/bin/conda/conda_envs/gemoma/share/gemoma-1.7.1-0/

# wrapper 스크립트 수정 (GeMoMa Python wrapper)
# jar_file = 'GeMoMa-1.7.1.jar'  →  jar_file = 'GeMoMa-1.9.jar'
```

### 3. 확인
```bash
micromamba run -n gemoma GeMoMa          # → "latest GeMoMa version"
micromamba run -n gemoma GeMoMa GeMoMaPipeline  # → version: 1.9
micromamba run -n gemoma java -version   # → openjdk 11.0.9.1
micromamba run -n gemoma mmseqs version  # → 13.45111
```

## Key Paths
- Env: `/data/gpfs/assoc/pgl/bin/conda/conda_envs/gemoma/`
- JAR: `.../share/gemoma-1.7.1-0/GeMoMa-1.9.jar`
- Wrapper: `.../share/gemoma-1.7.1-0/GeMoMa`
- Old JAR (preserved): `.../share/gemoma-1.7.1-0/GeMoMa-1.7.1.jar`
