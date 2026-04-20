#!/bin/bash
set -e

# Remove PID antigo se existir
rm -f tmp/pids/*.pid

rails_console() {
  echo "Ambiente: $RAILS_ENV"
  echo "rails db:migrate"
  rails db:migrate
  echo "INICIANDO rails console"
  rails c
}

server() {
  if [ "$RAILS_ENV" = 'development' ] && [ "$DATABASE_HOST" = 'postgres' ]; then
    echo "rails db:create"
    rails db:create

    echo "rails db:migrate"
    rails db:migrate

    echo "rails db:seed"
    rails db:seed
  fi

  echo "INICIANDO rails s -b 0.0.0.0"
  rails s -b 0.0.0.0
}

run_test() {
  if [ "$RAILS_ENV" = 'test' ] && [ "$DATABASE_HOST" = 'postgres' ]; then
    bin/rails db:environment:set RAILS_ENV=test

    echo "rails db:drop"
    RAILS_ENV=test rails db:drop

    echo "rails db:create"
    RAILS_ENV=test rails db:create

    echo "rails db:migrate"
    RAILS_ENV=test rails db:migrate
  fi

  echo "rails rswag"
  rails rswag:specs:swaggerize

  echo "INICIANDO testes"
  RAILS_ENV=test bundle exec rspec -f documentation
}

info() {
  echo ""
  echo "$(date)"
  echo ""
  echo "##############################"
  echo "# Ambiente: $RAILS_ENV"
  echo "# Database:"
  echo "#   Host: $DATABASE_HOST"
  echo "#   Name: $DATABASE_NAME"
  echo "#   Port: $DATABASE_PORT"
  echo "##############################"
  echo ""
}

info

SERVICE=${1:-server}

if ! bundle check > /dev/null 2>&1; then
  echo "bundle install"
  bundle install
else
  echo "Dependencias OK"
fi

case "$SERVICE" in
  rails_console) rails_console ;;
  bash)          bash ;;
  test)          run_test ;;
  *)             server ;;
esac

echo "$(date)"
