export const config = {
    api_endpoint: process.env.NODE_ENV == 'production' ? '/api' : 'http://localhost:8080/api'
}