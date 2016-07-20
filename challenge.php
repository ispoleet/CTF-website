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
    <?php 
    /* -------------------------------------------------------------------------------- */
        require( 'utils.php' );                 // import core security functions

        session_start();                        // start session

        if( !isset( $_SESSION['uid'] ) ) {      // not logged in?
            header('Location: index.php');      // redirect
            exit;                               // don't forget this!
        }

        prntnavbar();                           // print navigation bar
       

             if( isset($_POST['id']) ) $cid = intsafe($_POST['id']);
        else if( isset($_GET ['id']) ) $cid = intsafe($_GET ['id']);
        else $cid = -1;
        
        if( $cid !== -1 )                       // do we have a valid challenge ID?
        {
            // fetch challenge info
            $conn = dbconn();                   // connect to the DB server

            if( !($stmt = $conn->prepare
                    (
                        "SELECT name, initpoints, difficulty, link, description, hint, " .
                            "points, solves " .
                        "FROM challenges " .
                        "   INNER JOIN dynchall ON challenges.cid = dynchall.cid " .
                        "WHERE challenges.cid=? LIMIT 1"
                    ) ) ||
                ! $stmt->bind_param("i", $cid) ||    
                ! $stmt->execute() ||                   
                ! $stmt->bind_result($name, $initpoints, $diff, $link, $descr, $hint, 
                                     $points, $solves) ||           
                ! $stmt->fetch() )              // fetch value; error if empty set returned
            {
                $cid = -1;                      // set error
            }
            
            $stmt->close();                     // close statement
            $conn->close();                     // and db connection
            
        }

        if( $cid === -1 )                       // I couldn't fetch the challenge
        {            
            header('Location: dashboard.php');  // go to dashboard
            exit;
        }

        // challenge info ok. Go on.

    /* -------------------------------------------------------------------------------- */
    ?>

  <div class="container">
    <div class="jumbotron">
      <h1>
        <?php echo $_SESSION['chal'][$cid]['name'] . " Challenge #".
                   $_SESSION['chal'][$cid]['id']; ?> 
      </h1>
      <br/><br/>     
      
      <table class="table center-table">
        <tbody>
          <tr><td class='col-md-2'>Name       </td><td><?php echo $name; ?></td></tr>
          <tr><td class='col-md-2'>Description</td><td><?php echo $descr;?></td></tr>
          <tr><td class='col-md-2'>Difficulty </td><td><?php echo $diff;?></td></tr>
          <tr><td class='col-md-2'>Points     </td>
              <td><?php echo "$points (original $initpoints)";?></td>
          </tr>
          <tr><td class='col-md-2'>Solvers    </td><td><?php echo $solves ." (students only)";?></td></tr>
          <tr><td class='col-md-2'>Link       </td>
            <td> 
            <?php
              if( $link === "" ) echo "There is no link";
              else echo "<a href=\"$link\">Challenge Link</a>";
            ?>
            </td>
          </tr>
          <tr><td class='col-md-2'>Hints      </td>
            <td>
                <?php echo (strlen($hint) > 0 ? $hint : "There aren't any hints yet.")?>
            </td>
          </tr>        
        </tbody>
      </table>
      </br>

      <?php
      /* -------------------------------------------------------------------------------- */        
        if( isset($_POST['authflag']) &&        // submit a flag?
            isset($_POST['flag'])     &&
            isset($_POST['id']) )
        {
            if( chktok($_POST['token']) == -1 )
              die( 'CSRF attempt!');            // csrf detected            

            $cid  = intsafe($_POST['id']);      // sanitize integer
            $flag = sqlsafe($_POST['flag']);    // sanitize flag
            $slvd = authflag($cid, $flag);      // check if flag is valid.
                                                // if so update all tables
            if( $slvd == chst::error )
                die;                            // something went wrong

        } else $slvd = chst::none;              // haven't submit anything

      
        // We check first if flag is correct and then if it's already solved.
        // This because if flag is correct, $_SESSION['chal'][$cid]['slvd']
        // will be 1 and we'll always be on "solved" statement
        if( $slvd === chst::correct )           // flag was correct
        {
            ?>
                <div class="alert alert-success" role="alert">
                    <span class="glyphicon glyphicon-ok" aria-hidden="true"></span>
                    Correct Flag! You got <?php echo $points; ?> points!
                </div>
            <?php
        }  
        else if( $_SESSION['chal'][$cid]['slvd'] === 1 ||
            $slvd === chst::solved )            // already solved challenge?
        {
            ?>                
                <div class="alert alert-success" role="alert">
                    <span class="glyphicon glyphicon-ok" aria-hidden="true"></span>
                    You have already solved this challenge.
                </div>
            <?php
        }
        else {                                  

            if( $slvd === chst::wrong )         // wrong flag?
            {
                ?>                
                    <div class="alert alert-danger" style="text-align:left" role="alert">
                        <span class="glyphicon glyphicon-remove" aria-hidden="true">
                        </span>
                        Wrong Flag! :( You shoud try harder...
                    </div>
                <?php
            }
            else if( $slvd === chst::expired )  // expired flag?
            {
                ?>                
                    <div class="alert alert-danger" style="text-align:left" role="alert">
                        <span class="glyphicon glyphicon-remove" aria-hidden="true">
                        </span>
                        Flag expired.
                    </div>
                <?php
            }

            // in any case display submit-flag form

      /* -------------------------------------------------------------------------------- */
      ?>
      <!-- flag sumbit form -->
      <div class="container">
        <form class="form-horizontal" role="form"  method="post" action="challenge.php" autocomplete="off">

          <!-- generate a unique, unpredictable token to prevent CSRF attacks -->
          <input type="hidden" name="token" value="<?php echo gentok();?>" />
          <input type="hidden" name="id"    value="<?php echo $cid;?>" />
          
          <div style="margin-bottom: 25px" class="input-group">
            <span class="input-group-addon">
              <i class="glyphicon glyphicon-flag"></i>
            </span>
            
            <input id="login-username" type="text" class="form-control col-lg-1" maxlength="128"
                          name="flag" value="" placeholder="Enter the flag here" required="true">
          </div>        
          
          <div style="margin-top:10px" class="form-group">
            <div class="col-sm-12 controls">
              <button type="submit" name="authflag" value="" class="btn btn-logout">
                <b>Submit</b>
              </button>
            </div>                               
          </div>

        </form>
      </div>
        
    <?php } /* this is important! */ ?> 

    </div> <!-- jumbotron -->

    <?php prntfooter(); ?>

  </div> <!-- container -->                                  
</body>
<!--====================================================================================================-->
</html>
