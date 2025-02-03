import express from 'express';
import { exec } from 'child_process';

// ------------------------------
// Constants
// ------------------------------

const port = process.env.PORT || 8080;

const wwwPath = '/home/junivision/junivision/web/public';

const deviceByType = {
  bench: '/dev/video0',
  board: '/dev/video1',
};

const streamVideoCommands = {
  // Logitech MX Brio
  bench: `gst-launch-1.0 v4l2src device=${deviceByType.bench} ! video/x-raw, format=YUY2, width=3840, height=2160, framerate=5/1 ! videoconvert ! videoflip method=clockwise ! x264enc tune=zerolatency bitrate=2048 speed-preset=ultrafast key-int-max=15 ! h264parse ! mpegtsmux ! hlssink location=${wwwPath}/stream-%05d.ts target-duration=1 max-files=10 playlist-location=${wwwPath}/stream.m3u8 playlist-length=10`,
  // MOKOSE 4K
  board: `gst-launch-1.0 v4l2src device=${deviceByType.bench} ! video/x-raw, format=YUY2, width=3840, height=2160, framerate=5/1 ! videoconvert ! x264enc tune=zerolatency bitrate=2048 speed-preset=ultrafast key-int-max=15 ! h264parse ! mpegtsmux ! hlssink location=${wwwPath}/stream-%05d.ts target-duration=1 max-files=3 playlist-location=${wwwPath}/stream.m3u8 playlist-length=3`,
};

const session = {
  ts: null, // epoch timestamp
};

// ------------------------------
// Server
// ------------------------------

const app = express();
app.use(express.json());

app.use((_req, _res, next) => {
  session.ts = Date.now();
  next();
});

// Serve static files from the "web" directory
app.use(express.static('public'));

app.get('/api/status', handlerAsync(statusInfo));
app.get('/api/usb', handlerAsync(usbInfo));
app.get('/api/node', handlerAsync(nodeInfo));
app.get('/api/stream', handlerAsync(streamInfo));
app.post(
  '/api/stream',
  handlerAsync(async (req) => startStream(req.body.scene))
);

// Start the server
app.listen(port, () => {
  console.log(`🚀 Web server running at http://localhost:${port}`);
});

stopStreamIfInactive(30);

// ------------------------------
// Actions
// ------------------------------

async function statusInfo() {
  const usb = await usbInfo();
  const node = await nodeInfo();
  const stream = await streamInfo();
  return { usb, node, stream, wwwPath };
}

async function usbInfo() {
  const usbLines = await execAsync('lsusb').catch((err) => {
    console.error('Error running lsusb', err);
    return null;
  });
  if (!usbLines) return [];
  return usbLines.split('\n').map((line) => {
    const [bus, device] = line.match(/Bus (\d+) Device (\d+)/)?.slice(1) ?? [];
    return { bus, device, description: line };
  });
}

async function nodeInfo() {
  const versionLines = await execAsync('node -v && npm -v');
  const [nodeVersion, npmVersion] = versionLines.split('\n');
  return { nodeVersion, npmVersion };
}

async function streamInfo() {
  const infoLine = await execAsync(
    `lsof -c gst-launch | grep /dev/video | awk '{print "pid:", $2, "; device:", $NF}' | sort -u`
  );
  const info = infoLine.split(';').reduce((acc, line) => {
    const [key, value] = line.split(':').map((s) => s.trim());
    acc[key] = value;
    return acc;
  }, {});
  const type = Object.entries(deviceByType).reduce((value, [key, device]) => {
    return value || (info.device === device ? key : undefined);
  }, undefined);
  return { ...info, type };
}

async function stopStream(currStream) {
  currStream = currStream ?? (await streamInfo());
  if (currStream.pid) {
    // Just in case
    await execAsync(`kill ${currStream.pid}`).catch((err) => {
      console.error(`Error stopping stream process with PID ${currStream.pid}:`, err);
    });
  }
}

async function startStream(type) {
  const currStream = await streamInfo();
  if (currStream.type === type) {
    return;
  }
  await stopStream();
  const command = streamVideoCommands[type];
  if (!command) {
    throw new Error(`Unknown stream type: ${type}`);
  }
  const process = exec(command, (err, stdout, stderr) => {
    if (err) {
      console.error(`Error running stream command for '${type}'`, err);
    }
  });
  process.on('exit', () => {
    console.log(`Stream process for '${type}' exited`);
  });
  process.on('error', (err) => {
    console.error(`Error running stream command for '${type}'`, err);
  });
  process.on('message', (message) => {
    console.log(`Stream message for '${type}':`, message);
  });

  return streamInfo();
}

async function stopStreamIfInactive(recheckInSecs = 30) {
  const stream = await streamInfo();
  if (!stream?.pid) return; // no stream running
  const elapsedSecsSinceActivity = (Date.now() - session.ts) / 1000;
  if (elapsedSecsSinceActivity > 60) {
    await stopStream();
  }
  if (recheckInSecs) {
    setTimeout(() => stopStreamIfInactive(recheckInSecs), recheckInSecs * 1000);
  }
}

// ------------------------------
// Helpers
// ------------------------------

/**
 * @template T
 * @param {(req: Request) => Promise<T>} handler
 * @returns {(req: Request, res: Response) => Promise<void>}
 */
function handlerAsync(handler) {
  return async (req, res) => {
    try {
      const result = await handler(req);
      res.json(result);
    } catch (error) {
      res.status(error?.statusCode ?? 500).json({ error: error.message ?? 'Unknown error' });
    }
  };
}

/** @param {string} command*/
async function execAsync(command) {
  /** @type {Promise<string>} */
  const result = new Promise((resolve, reject) => {
    exec(command, (err, stdout, stderr) => {
      if (err) {
        reject(err);
      } else {
        resolve(stdout);
      }
    });
  });
  return result;
}
