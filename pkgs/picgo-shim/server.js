import { PicGo } from 'picgo'
import s3Plugin from 'picgo-plugin-s3'

const picgo = new PicGo()
picgo.use(s3Plugin, 'aws-s3')
picgo.setConfig({
  picBed: {
    current: 'aws-s3',
    uploader: 'aws-s3',
    'aws-s3': {
      endpoint: process.env.PICGO_S3_ENDPOINT,
      region: process.env.PICGO_S3_REGION,
      bucketName: process.env.PICGO_S3_BUCKET,
      accessKeyID: process.env.PICGO_S3_KEY,
      secretAccessKey: process.env.PICGO_S3_SECRET,
      acl: process.env.PICGO_S3_ACL || "public-read",
      pathStyleAccess: process.env.PICGO_S3_PATH_STYLE_ACCESS || false,
      uploadPath: process.env.PICGO_S3_UPLOAD_PATH_PATTERN || "{year}/{md5}.{extName}",
      outputURLPattern: process.env.PICGO_S3_OUTPUT_URL_PATTERN
    }
  },
  'settings.server': {
    host: process.env.PICGO_HOST,
    port: process.env.PICGO_PORT,
  }
})

// compatibility layer for piclist apps
picgo.server.registerPost('/shim', async (c) => {
  const err = (message, status = 400) => c.json({ success: false, result: [], message }, status)

  try {
    const raw = Buffer.from(await c.req.arrayBuffer())

    const headerEnd = raw.indexOf('\r\n\r\n')
    const [skip, closing] = headerEnd !== -1 ? [4, '\r\n--'] : [2, '\n--']
    const bodyStart = headerEnd !== -1 ? headerEnd : raw.indexOf('\n\n')

    if (bodyStart === -1) return err('Malformed multipart: no header boundary')
    const bodyEnd = raw.lastIndexOf(closing)
    if (bodyEnd === -1) return err('Malformed multipart: no closing boundary')

    const imageBuffer = raw.subarray(bodyStart + skip, bodyEnd)

    const result = await picgo.upload([imageBuffer])
    if (result instanceof Error) return err(result.message, 500)

    const urls = result.map(item => item.imgUrl).filter(url => typeof url === 'string' && url !== '')
    return c.json({ success: true, result: urls })
  } catch (e) {
    return err(e.message, 500)
  }
})

await picgo.server.listen()
