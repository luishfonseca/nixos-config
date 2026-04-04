import { PicGo } from 'picgo'
import s3Plugin from 'picgo-plugin-s3'
import CompressTransformers from 'picgo-plugin-compress-next'

import { join } from 'path'
import { tmpdir } from 'os'
import { writeFileSync, mkdtempSync, rmSync } from 'fs'
import busboy from 'busboy'

const picgo = new PicGo()
picgo.use(s3Plugin, 'aws-s3')
picgo.use(CompressTransformers, 'compress-next')
picgo.setConfig({
  picBed: {
    transformer: 'compress-next',
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
  'compress-next': {
    'Compress Type': 'imagemin-webp',
    'Gif compress Type': 'imagemin-gif2webp',
  },
  'settings.server': {
    host: process.env.PICGO_HOST,
    port: process.env.PICGO_PORT,
    secret: process.env.PICGO_SECRET,
  }
})

// compatibility layer for piclist apps
picgo.server.registerPost('/shim', async (c) => {
  const err = (message, status = 400) => c.json({ success: false, result: [], message }, status)

  const { tmpPaths, reqDir } = await new Promise((resolve, reject) => {
    const bb = busboy({ headers: Object.fromEntries(c.req.raw.headers) })
    const reqDir = mkdtempSync(join(tmpdir(), 'picgo-'))
    const paths = []

    bb.on('file', (_, stream, { filename }) => {
      if (!filename) return reject(new Error('Multipart file missing filename'))

      const tmp = join(reqDir, filename)
      paths.push(tmp)

      const chunks = []
      stream.on('data', chunk => chunks.push(chunk))
      stream.on('end', () => writeFileSync(tmp, Buffer.concat(chunks)))
      stream.on('error', reject)
    })

    bb.on('finish', () => resolve({ tmpPaths: paths, reqDir }))
    bb.on('error', reject)

    c.req.raw.body.pipeTo(new WritableStream({
      write: chunk => bb.write(chunk),
      close: () => bb.end(),
    }))
  })

  try {
    const result = await picgo.upload(tmpPaths)
    if (result instanceof Error) return err(result.message, 500)
    const urls = result.map(i => i.imgUrl).filter(url => typeof url === 'string' && url !== '')
    return c.json({ success: true, result: urls })
  } catch (e) {
    return err(e.message, 500)
  } finally {
    rmSync(reqDir, { recursive: true, force: true })
  }
})

await picgo.server.listen()
