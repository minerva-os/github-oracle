var express = require("express");
var router = express.Router();

var { getRepositoryList, getClosedPulls } = require("../controllers/repositoryController");

router.get("/", getClosedPulls);

module.exports = router;
