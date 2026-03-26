import express from "express";

const app = express();
const port = Number(process.env.PORT ?? 8080);

app.get("/healthz", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.listen(port, () => {
  // Keep startup logs simple for local debugging.
  console.log(`server listening on ${port}`);
});
