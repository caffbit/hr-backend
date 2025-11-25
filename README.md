<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

HR Backend - A Human Resources management system built with NestJS, TypeORM, and MySQL.

### Features

- ✅ **NestJS 11** - Latest framework version
- ✅ **TypeORM** - Database ORM with migration support
- ✅ **MySQL 8.0** - Production-ready database
- ✅ **Docker Compose** - Containerized development and production environments
- ✅ **Docker Secrets** - Secure credential management for production
- ✅ **Environment Configuration** - Type-safe config with @nestjs/config
- ✅ **Base Entity Pattern** - UUID, timestamps, and soft delete support

## Project setup

```bash
$ pnpm install
```

### Database Setup

This project uses MySQL with TypeORM. Database credentials are managed differently for development and production:

- **Development**: Environment variables in `compose.dev.yaml`
- **Production**: Docker Secrets for enhanced security

See [PRODUCTION.md](./PRODUCTION.md) for production deployment guide.

## Development with Docker

### Start development environment

```bash
# Start MySQL and application with hot-reload
$ docker compose -f compose.dev.yaml up -d

# View logs
$ docker logs hr-backend-dev -f

# Stop services
$ docker compose -f compose.dev.yaml down
```

The application will be available at `http://localhost:3000`

### Database Migrations

```bash
# Generate migration from entity changes
$ pnpm run migration:generate src/database/migrations/MigrationName

# Create empty migration
$ pnpm run migration:create src/database/migrations/MigrationName

# Run pending migrations
$ pnpm run migration:run

# Revert last migration
$ pnpm run migration:revert

# Show migration status
$ pnpm run migration:show
```

## Compile and run the project (local)

```bash
# development
$ pnpm run start

# watch mode
$ pnpm run start:dev

# production mode
$ pnpm run start:prod
```

**Note**: When running locally (not in Docker), ensure MySQL is accessible and update `.env` with correct `DB_HOST`.

## Run tests

```bash
# unit tests
$ pnpm run test

# e2e tests
$ pnpm run test:e2e

# test coverage
$ pnpm run test:cov
```

## Production Deployment

This project uses **Docker Secrets** for secure credential management in production.

### Quick Setup

1. **Initialize secrets** (one-time setup):
   ```bash
   $ bash scripts/setup-secrets.sh
   ```

2. **Deploy to production**:
   ```bash
   $ docker compose -f compose.prod.yaml up -d
   ```

3. **Run database migrations**:
   ```bash
   $ docker exec hr-backend-prod pnpm run migration:run
   ```

### Security Features

- 🔒 Database credentials stored as Docker Secrets (not environment variables)
- 🔒 Secrets mounted to `/run/secrets/` (encrypted tmpfs)
- 🔒 Automatic secret rotation support
- 🔒 `.gitignore` configured to prevent committing secrets

For detailed production deployment instructions, see [PRODUCTION.md](./PRODUCTION.md).

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
