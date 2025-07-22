// init-mongo.js
db = db.getSiblingDB("admin");  // 切换到admin数据库

// 创建root用户（修改用户名和密码）
db.createUser({
  user: "root",
  pwd: "xqkeji.cn",  // 请使用强密码！
  roles: [
    { role: "root", db: "admin" }  // root角色拥有最高权限
  ]
});
