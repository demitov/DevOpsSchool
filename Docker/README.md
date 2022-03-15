# Docker homework

Clone repository and go to Docker directory
```
git clone https://github.com/demitov/DevOpsSchool.git

cd DevOpsSchool/Docker
```

Create a file *database.env* with the following content:
```
POSTGRES_USER=django
POSTGRES_PASSWORD=django
POSTGRES_DB=django
```

To build project run in project root directory:
```
docker-compose build
```

Then run:
```
docker-compose up -d
```

After start containers open in browser address
[http://localhost:3000](http://localhost:3000)