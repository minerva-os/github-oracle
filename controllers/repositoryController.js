const { Octokit } = require("@octokit/rest");

exports.getClosedPulls = async (req, res) => {
  var octokit;
  var closedPulls;

  var startDate = new Date();
  startDate.setDate(startDate.getDate() - 1);
  startDate.setHours(0, 0, 0, 0);

  var endDate = new Date(startDate);
  endDate.setHours(23, 59, 59, 999);

  try {
    octokit = new Octokit();
    closedPulls = await octokit.rest.pulls.list({
      owner: req.query.user,
      repo: req.query.repo,
      state: "closed",
      sort: "updated",
      direction: "desc",
    });

    var lastPulls = closedPulls.data.filter((element) => {
      let mergeDate = new Date(element.merged_at);
      return (
        element.merge_commit_sha && mergeDate > startDate && mergeDate < endDate
      );
    });

    var data = lastPulls.map(({ user }) => user);
    var user = data.map(({ id }) => id);

    res.json({
      data: user,
    });
  } catch (err) {
    console.log(err);
    res.status(500).json({
      error: err,
    });
  }
};
