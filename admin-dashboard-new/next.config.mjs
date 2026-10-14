/** @type {import('next').NextConfig} */
const nextConfig = {
  devIndicators: false,
  async rewrites() {
    // Proxy /api/* vers le backend du VPS (évite le blocage mixed-content
    // quand le dashboard est servi en HTTPS par Vercel)
    return [
      {
        source: '/api/:path*',
        destination:
          (process.env.API_BACKEND_URL || 'http://185.98.128.123:3001/mykog-api/api') +
          '/:path*',
      },
    ]
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
}

export default nextConfig
