import { registerAs } from '@nestjs/config';
import { DataSourceOptions } from 'typeorm';
import { readFileSync } from 'fs';

/**
 * Read Docker secret from file system
 * In production, Docker Swarm/Compose mounts secrets at /run/secrets/
 */
function getSecret(secretName: string, fallback?: string): string {
  try {
    const secretPath = `/run/secrets/${secretName}`;
    return readFileSync(secretPath, 'utf8').trim();
  } catch {
    return fallback || '';
  }
}

export default registerAs(
  'database',
  (): DataSourceOptions => {
    // In production, try to read from Docker secrets first
    const username =
      getSecret('mysql_user') || process.env.DB_USERNAME || 'root';
    const password =
      getSecret('mysql_password') || process.env.DB_PASSWORD || '';

    return {
      type: 'mysql',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306', 10),
      username,
      password,
      database: process.env.DB_DATABASE || 'hr_database',
      entities: [__dirname + '/../**/*.entity{.ts,.js}'],
      migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
      synchronize: process.env.DB_SYNCHRONIZE === 'true' || false,
      logging: process.env.DB_LOGGING === 'true' || false,
      extra: {
        connectionLimit: parseInt(process.env.DB_POOL_MAX || '10', 10),
      },
    };
  },
);
