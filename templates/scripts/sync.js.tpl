const watch = require('watch');
const { exec } = require('child_process');

const app_root = '${app_root}';
const bucket = '${static_content_bucket}';

watch.watchTree(app_root + '/wp-includes', (f, curr, prev) => {
  if (typeof f == 'object' && prev === null && curr === null) {
    return;
  } else {
    const relativepath = f.split('wp-includes/')[1];
    // Not using interpolation in exec() to avoid conflicts with .tpl syntax
    if (curr.nlink === 0) {
      // f was removed
      //exec('aws s3 rm s3://' + bucket + '/' + relativepath);
    } else {
      // f is new or was changed
      exec('aws s3 cp ' + f + ' s3://' + bucket + '/' + relativepath);
    }
  }
});
