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
			<h1>Scoreboard</h1>
			</br></br>
			<center><i> (Highlighted names are not students)</i></center>

			<table class="table center-table">
				<thead> <tr>
						<th class='col-md-1'>##    </th>
						<th class='col-md-8'>Name  </th>
						<th class='col-md-8'>Type  </th>
						<th class='col-md-2'>Points</th>
				</tr> </thead>
				<tbody>
				
				<?php
				/* -------------------------------------------------------------------------------- */            
						$conn = dbconn();                       // connect to the DB server    
						$uid  = sqlsafe( $_SESSION["uid"] );    // user id

						if( !($stmt = $conn->prepare(
									"SELECT alias, type, points FROM r4nK__ ORDER BY points DESC"
									)) ||                             // do not display students except yourself
								! $stmt->execute() ||         
								! $stmt->bind_result($alias, $type, $points) )
						{
								$stmt->close();                     // close prepared statement
								$conn->close();                     // close db connection
								die;                                // something went wrong
						}           

						for( $i=1; $stmt->fetch(); $i=$i+1 )    	// start fetching records
						{
								if(!is_numeric($points) ) die;      // db has been compromised

								$alias  = htmlsafe($alias);         // sanitize them before display 
								$type   = htmlsafe($type); 
								$points = htmlsafe($points);


								if( $alias === "" ) continue;		// do not display blank names

								echo "<tr class='$type'><td>$i</td><td>";

								if( $i == 1 )                       // top player gets the crown
								{
				?>
				
				<img class="partner" src="images/crown.png" height="20" data-toggle="tooltip" 
								data-placement="bottom">
				
				<?php 
								}

								echo "$alias</td> <td>$type</td> <td>$points</td> </tr>";
						}

						$stmt->close();                         // close prepared statement
						$conn->close();                         // close db connection
				/* -------------------------------------------------------------------------------- */
				?>      
					
				</tbody>
			</table> </br>      
		</div> <!-- jumbotron -->

	<?php prntfooter(); ?>
	
	</div> <!-- container -->

</body>
<!--====================================================================================================-->
</html>

