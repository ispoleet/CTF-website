<!DOCTYPE html>
<html lang="en">
<!--====================================================================================================-->
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport"              content="width=device-width, initial-scale=1">
  <meta name="description"           content="CS527 Software Security">
  <meta name="author"                content="ispo">

  <!-- our CSS: Bootstrap and our customization -->
  <link href="css/bootstrap.min.css" rel="stylesheet">
  <link href="css/custom.css"        rel="stylesheet">
  <link href="favicon.ico"           rel="icon">

  <title>CS527 Software Security</title>
</head>
<!--====================================================================================================-->
<body>
  <div class="container">
    <div class="jumbotron">
      <h1>CS527 - Software Security</h1>
      </br>
        <p> Welcome to CS527 (Software Security) class. Here, you can access lab assignments.
            All of the assigments are in a <a href="https://ctftime.org/ctf-wtf/">Capture The Flag</a> 
            flavor. For each problem the goal is simple: Find the flag and submit it to get points!
            However the <i>"find the flag"</i> part won't be so simple...
        </p>
        </br></br>
        
        <?php 
        /* -------------------------------------------------------------------------------- */
            require( 'utils.php' );                 // import core security functions
            
            session_start();                        // start session

            if( isset( $_SESSION['uid'] ) ) {       // already logged in?
                header('Location: dashboard.php');  // redirect
                exit;                               // don't forget this!
            }

            if( isset($_POST['username']) && isset($_POST['password']) )
            {
                if( chktok($_POST['token']) == -1 )
                    die( 'CSRF attempt!');          // csrf detected

                // do our secure authentication
                if( authusr($_POST['username'], $_POST['password']) != -1 ) {
                    // login ok                 
                    header('Location: dashboard.php');
                    exit;
                }

                // login failed
                echo '<div class="alert alert-danger" style="margin:auto"; role="alert">' .
                     '<span class="glyphicon glyphicon-remove" aria-hidden="true"></span> '.
                     'Login Failed</div>';
            }
        /* -------------------------------------------------------------------------------- */
        ?>

        <div class="container">
         <div id="loginbox" style="margin-top:25px;" 
                           class="mainbox col-md-8 col-md-offset-2 col-sm-8 col-sm-offset-2">
            <div class="panel panel-info" >
              <div class="panel-heading">
                <div class="panel-title">Login</div>
                <div style="float:right; font-size: 80%; position: relative; top:-10px">
                  (Register only by invitation)
                </div>
              </div>     

            <div style="padding-top:30px" class="panel-body" >
              <div style="display:none" id="login-alert" class="alert alert-danger col-sm-12"></div>

                <!-- our login form -->
                <form method="post" action="index.php" class="form-horizontal" role="form">                
                  <div style="margin-bottom: 25px" class="input-group">
                    <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>

                    <input id="login-username" type="text" name="username" value=""
                           placeholder="Username" maxlength="64" class="form-control" required="true">
                  </div>

                  <div style="margin-bottom: 25px" class="input-group">
                    <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i></span>

                      <input id="login-password" type="password" name="password" value=""
                             class="form-control" placeholder="Password" maxlength="64" required="true">
                  </div>    

                  <!-- generate a unique, unpredictable token to prevent CSRF attacks -->
                  <input type="hidden" name="token" value="<?php echo gentok();?>" />

                  <div style="margin-top:10px" class="form-group">
                    <div class="col-sm-12 controls">
                      <button type="submit" name="submit" class="btn btn-primary">Let me in</button>
                    </div>                               
                  </div>
                  
                  <div class="form-group">
                    <div class="col-md-12 control">
                      <div style="border-top: 1px solid#888; padding-top:15px; font-size:85%" >
                        Forgot your password? Contact
                        <i><a href="images/mailme.jpg">admin</a></i>
                        <i class="glyphicon glyphicon-heart"></i>
                        <i class="glyphicon glyphicon-heart"></i>
                        <i class="glyphicon glyphicon-heart"></i>
                      </div>
                    </div>
                  </div>    
                </form> <!-- form ends here -->

              </div>
            </div> 
          </div>
        </div> <!-- loginbox -->
    </div> <!-- jumbotron -->

    <?php prntfooter(); ?>

  </div> <!-- container -->
</body>
<!--====================================================================================================-->
</html>
