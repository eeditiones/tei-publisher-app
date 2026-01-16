#!/usr/bin/env bats

# Basic start-up and connection tests
# These tests expect a running container at port 8080 with the name "exist"
# Port 8080 is hardcoded as assumption

@test "container jvm responds from client" {
  run docker exec exist java -version
  [ "$status" -eq 0 ]
}

@test "container can be reached via http" {
  result=$(curl -Is http://127.0.0.1:8080/ | grep -o 'Jetty')
  [ "$result" == 'Jetty' ]
}

@test "container reports healthy to docker" {
  result=$(docker ps | grep -c 'healthy')
  [ "$result" -eq 1 ]
}

@test "logs show clean start" {
  result=$(docker logs exist | grep -o 'Server has started')
  [ "$result" == 'Server has started' ]
}

# Make sure the package has been deployed
# Expected count is number of declared expath dependencies + 1 (the app itself)
@test "logs show package deployment" {
  result=$(docker logs exist | grep -ow -c 'https://e-editiones.org/apps/tei-publisher')
  expected=4
  [ "$result" -eq $expected ]
}

@test "application responds" {
  result=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/exist/apps/tei-publisher/)
  [ "$result" -eq 200 ]
}

@test "logs are error free" {
  result=$(docker logs exist | grep -ow -c 'ERROR' || true)
  [ "$result" -eq 0 ]
}

@test "no fatalities in logs" {
  result=$(docker logs exist | grep -ow -c 'FATAL' || true)
  [ "$result" -eq 0 ]
}

# Check for cgroup config warning 
@test "check logs for cgroup file warning" {
  result=$(docker logs exist | grep -ow -c 'Unable to open cgroup memory limit file' || true)
  [ "$result" -eq 0 ]
}
