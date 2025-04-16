#!/bin/bash

function wait_for_container {
  container_name=$1
  timeout=$2
  # might need to look up the name outside docker compose
  start_time=`date +%s`
  function get_elapsed {
    current_time=`date +%s`
    echo $((current_time-start_time))
  }
  function check_elapsed {
    [ "$timeout" == "" ] && return 0
    elapsed=`get_elapsed`
    return $((elapsed>=timeout))
  }
  echo -n "Waiting for $container_name... "
  until [ "$(docker inspect -f {{.State.Running}} $(docker compose ps --format '{{.Name}}' ${container_name} 2>/dev/null) 2>/dev/null)" == "true" ]
    do
      sleep 0.5
      check_elapsed || { echo timeout >&2 ; return ; }
    done
  echo -n "started... "
  until [ "$(docker inspect -f {{.State.Health.Status}} $(docker compose ps --format '{{.Name}}' ${container_name} 2>/dev/null) 2>/dev/null)" == "healthy" ]
    do
      sleep 0.5
      check_elapsed || { echo timeout >&2 ; return ; }
    done
  echo "complete"
}

function wait_for_containers {
  timeout=$1
  shift 1
  container_names="$@"
  # might need to look up the name outside docker compose
  start_time=`date +%s`
  function get_elapsed {
    current_time=`date +%s`
    echo $((current_time-start_time))
  }
  function check_elapsed {
    [ "$timeout" == "" ] && return 0
    elapsed=`get_elapsed`
    return $((elapsed>=timeout))
  }
  echo -n "Waiting for $container_names... "
  all_started=
  until [ "$all_started" == "true" ]
    do
      non_started=
      for container_name in $container_names
        do
          container_started="$(docker inspect -f {{.State.Running}} $(docker compose ps --format '{{.Name}}' ${container_name} 2>/dev/null) 2>/dev/null)"
          [ "$container_started" == "true" ] || non_started="$non_started $container_name"
        done
      [ "$non_started" == "" ] && all_started=true
      if [ "$non_started" != "" ]; then
        sleep 0.5
        check_elapsed || { echo timeout still waiting for "$non_started" to start >&2 ; return ; }
      fi
    done
  echo -n "started... "
  all_healthy=
  until [ "$all_healthy" == "true" ]
    do
      non_healthy=
      for container_name in $container_names
        do
          container_healthy="$(docker inspect -f {{.State.Running}} $(docker compose ps --format '{{.Name}}' ${container_name} 2>/dev/null) 2>/dev/null)"
          [ "$container_healthy" == "true" ] || non_healthy="$non_healthy $container_name"
        done
      [ "$non_healthy" == "" ] && all_healthy=true
      if [ "$non_healthy" != "" ]; then
        sleep 0.5
        check_elapsed || { echo timeout still waiting for "$non_healthy" to be healthy >&2 ; return ; }
      fi
    done
  echo "complete"
}

