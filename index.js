require('dotenv').config();
const express = require('express')
const cors = require('cors');

const PORT = process.env.PORT || 3000
const app = express();
app.use(cors());

app.get("/status", (req, res, next) => {
  console.log("status callled");
  res.status(200).json({ "status": "Running" });
})

app.get("/helloWorld" , (req,res,next)=>{
  res.status(200).json({"message" : "this is next version fully deployed using CI/CD on EC2 using ecr and docker installed on EC2 : v2 of code"})
}
)


app.listen(PORT, "0.0.0.0", () => {
  console.log(`search running on PORT ${process.env.PORT}`);
})


