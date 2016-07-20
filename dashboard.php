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
    /* -------------------------------------------------------------------------------- */
    ?>

  <div class="container">
    <div class="jumbotron">
      <h1>Challenges</h1>
      
      <?php
      /* -------------------------------------------------------------------------------- */
        prntusr();                              // print user's info

        // all challenge information are stored in session file to avoid asking the db
        // every time (we're in the home page, so we'll get this page many times)
        foreach( $_SESSION['chal'] as $cid => $r )
        {                      
            // 2nd MSNibble indicates challenge category (see utils for mapping)
            switch( ($cid & 0x0f000000) >> 24 )      
            {
                case 1 : $btn_type = "btn-re" ; break;
                case 2 : $btn_type = "btn-pwn"; break;
                case 3 : $btn_type = "btn-web"; break;
                case 4 : $btn_type = "btn-misc"; break;
                case 5 : $btn_type = "btn-real"; break;
                default: $btn_type = "";        // unknown category
            }

            // WARNING: we can have up to 6 challenges per category, otherwise
            // the banner will be fucked up. Thus we can change categories, but
            // giving them the same name and colors

            if( $r['chng'] == 1 )               // category changed?
                echo "\t\t</br></br>\n";        // change line too
            
            if( $r['slvd'] == 1 )               // if challenge is solved
                $btn_type .= " disabled";       // disable button

            // display button
            echo "\t\t" . "<a class='btn $btn_type' role='button' " .
                                "href='challenge.php?id=$cid'> " .
                                "<b>$r[name]<br/>#$r[id]</b>" .
                          "</a>&nbsp;\n";
        }

      /* -------------------------------------------------------------------------------- */
      ?>
    </br></br></br>    
    </div> <!-- jumbotron -->

    <?php prntfooter(); ?>

  </div> <!-- container -->                                  
</body>
<!--====================================================================================================-->
</html>

