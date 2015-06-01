function [ gamma, gamma_map, mean_dose, stdev ] = gamma_analysis( TPS, MC, DTA, d_criteria, threshold, van_dyk )

%                   Gamma Analysis Program
%               AUTHOR : SHARIF ELGUINDI, M.S.

% This function takes 5 INPUTS as follows:

% TPS is the fluence map from the treatment planning system (in absolute dose)
% MC is the mapcheck dose file (output of program mapcheck_opener)
% DTA is the distance to agreement threshold
% d_critera is the dose criteria 
% threshold is the threshold dose (in percent of max) at which to calculate
% points
% van_dyk is whether the dose criteria is assessed as a % of maximum dose
% in the plan, or of the local dose at the point of interest

% The TPS and MC files MUST be registered together, i.e, there matrix
% points correspond to each other (ex: row 25 col 25 of the mapcheck file 
% should in theory be the same point as row 25 col 25 of the TPS matrix you are
% comparing.

% This value (in cGy) determines at what dose difference between calculated
% and planned is actually acceptable.  If the dose difference is less than
% what is set here, the program will automatically make that dose difference zero.
% This is an option in the MapCheck software and defaults to 1 cGy.

dose_diff_uncertainty = 0;

%% Selection of Points to Analyze
% -----------------------------------------------------------------------
% This code finds the matrix index ' ind ' where dose was measured beyond
% the threshold.  It then pre-populates a gamma matrix of proper size
% for outputs to be calculated to (named 'gamma').  Finally, it converts
% the linear indices of the matrix to rows and columns in the 2 registered
% matrices and stores them in the variable  ' row_col '.
% -----------------------------------------------------------------------

%%% All Mapcheck Points above the threshold value (based on max dose)
[mapcheck_values] = find(MC>threshold*max(max(MC)));

%%% All TPS Points above the threshold value (based on max dose)
[tps_values] = find(TPS>threshold*max(max(TPS)));

%%% All Linear Indices of MapCheck points that have measured dose
[mapcheck_allpoints] = find(MC>0);
[tps_allpoints] = find(TPS>0);
%%% The combined set of indices between the Mapcheck and TPS that have dose
%%% above the threshold value set
C = union(mapcheck_values,tps_values); 

%%% This finds all the points in C that have measured dose to which a gamma
%%% analysis can be computed.
D = intersect(C,mapcheck_allpoints);

E = intersect(D,tps_allpoints);
%%% Initialize the gamma variable to output results as well as give the
%%% row,column indices of the gamma_map matrix to hold spatial information
gamma = zeros(length(E),3);
[j,k] = ind2sub(size(MC),E);

%% Compute the mean_dose difference between the planned and measured dose distributions
if van_dyk == 1
    mc_values = MC(E);
    tps_values = TPS(E);
    pct_diff = ((mc_values - tps_values)./max(tps_values));
    mean_dose = mean(pct_diff);
    stdev = std(pct_diff);
else 
    mc_values = MC(E);
    tps_values = TPS(E);
    pct_diff = ((mc_values - tps_values)./tps_values);
    non_inf =  (~isinf(pct_diff));
    mean_dose = mean(pct_diff(non_inf));
    stdev = std(pct_diff(non_inf));
end

mean_dose = 1 + mean_dose;

%% Store the row and column values in the variable to loop over
row_col(:,1) = j;
row_col(:,2) = k;


%% Variable Declaration
% -----------------------------------------------------------------------
% myCell is a cell matrix that is 5x201x201.  This is first prepopulated to
% all zeroes (for speed) and is 201x201 because each point on the mapcheck
% will be analyzed around a region of interest that is 2cm^2.  The MapCheck
% software only calculates gamma around a cirlce 8 mm in radius (1.6cm in
% diameter, and is suffcient for calculation (but can be adjusted).
% -----------------------------------------------------------------------
                                                       
myCell{1} = zeros(201,201);
myCell{2} = zeros(201,201);
myCell{3} = zeros(201,201);
myCell{4} = zeros(201,201);
myCell{5} = zeros(201,201);

% -----------------------------------------------------------------------
% This step extracts the indices of the 201x201 matrix.  Since these
% indices are postive values, we can convert them to distances with a
% simple -101 shift of all points so that the middle of the matrix
% corresponds to 0,0 (instead of the top corresponding to being
% 1,1).  Since this is a 2cm x 2cm box, each value corresponds to 0.1 mm,
% and absolute distance values from the middle point can be calculated.
% This is populated in myCell{2} matrix.
% -----------------------------------------------------------------------

[ix,iy] = find(myCell{2}==0);
distance_values(:,1) = ix;
distance_values(:,2) = iy;
distance_values(:,3) = ix-101;
distance_values(:,4) = (iy-101)*(-1);
distance_values(:,5) = sqrt(distance_values(:,3).^2 + distance_values(:,4).^2)*0.1;
linearind = sub2ind(size(myCell{1}),distance_values(:,1),distance_values(:,2));
myCell{2}(linearind) = distance_values(:,5);

% -----------------------------------------------------------------------
% Pre-populate a gamma map to plot the final gamma values with zeroes
% before entering loop.
% -----------------------------------------------------------------------

gamma_map = zeros(341,281);


%% Begin Point-by-Point analysis
% -----------------------------------------------------------------------
% The for loop steps through the length of the vector row_col, which is all
% the points in the mapcheck file that are higher than the dose threshold
% setting.
% -----------------------------------------------------------------------

for l = 1:length(row_col)

% -----------------------------------------------------------------------
% This step just puts the proper indices from row_col into variables for
% the mapcheck (MC) and planning system (TPS)
% -----------------------------------------------------------------------

row_MC = row_col(l,1);
col_MC = row_col(l,2);
row_TPS = row_col(l,1);
col_TPS = row_col(l,2);

% -----------------------------------------------------------------------
% This step takes the dose of the point in the TPS and expands it +/- 1cm
% and puts it in myCell{1}.  The myCell{1} is then a 201x201 matrix with
% values from the TPS in 1mm increments.
% -----------------------------------------------------------------------

myCell{1}(1:10:end,1:10:end) = TPS(row_TPS-10:1:row_TPS+10,col_TPS-10:1:col_TPS+10);

% -----------------------------------------------------------------------
% Interpolate ROI (2 cm^2) around middle of POI to 0.1 mm spacing.  
% It does this first between columns, and then between rows.
% -----------------------------------------------------------------------

% -----------------------------------------------------------------------
% Between Columns
% -----------------------------------------------------------------------

Y_0 = myCell{1}(:,1:10:end-10);
Y1_minus_Y0 = (myCell{1}(:,11:10:end) - myCell{1}(:,1:10:end-10));
d = 0.1;

for i=2:10
    myCell{1}(1:end,i:10:end) = Y_0 + Y1_minus_Y0.*d;
    d = d + 0.1;
end

% -----------------------------------------------------------------------
% Between Rows
% -----------------------------------------------------------------------

Y_0 = myCell{1}(1:10:end-10,:);
Y1_minus_Y0 = (myCell{1}(11:10:end,:) - myCell{1}(1:10:end-10,:));

d = 0.1;
for i=2:10
    myCell{1}(i:10:end,1:end) = Y_0 + Y1_minus_Y0.*d;
    d = d + 0.1;
end

% -----------------------------------------------------------------------
% Now we have a measured value (from mapcheck point) and a cell matrix in
% which myCell{1} is the dose around that mapcheck point from the planning
% system and myCell{2} the distance of each of those points to the center
% point, i.e the "distance to agreement".  
% -----------------------------------------------------------------------

% -----------------------------------------------------------------------
% subtract the dose from the MapCheck point in question from the doses in
% myCell{1} and put that in myCell{3}.  This is the dose difference
% locally.
% -----------------------------------------------------------------------
myCell{3} = (myCell{1} - MC(row_MC,col_MC)); 

% -----------------------------------------------------------------------
% This portion employs the dose difference uncertainty threshold set above.
% if any of the dose differences are less than what is defined, it will 
% make those a value of 0.
% -----------------------------------------------------------------------
[mapcheck_values] = find(abs(myCell{3})<dose_diff_uncertainty);
myCell{3}(mapcheck_values) = 0.0;

% -----------------------------------------------------------------------
% The next step divides the dose difference by the expected dose of the
% planning system.  The expected dose used is the TPS, not the measured
% value.  If you want to put the measured value, you can just replace:
%               myCell{1}(101,101) with MC(row_MC,col_MC) 
% in the line below.
% -----------------------------------------------------------------------
myCell{4} = myCell{3}./myCell{1}(101,101);  

if van_dyk == 1
    myCell{4} = myCell{3}./(max(max(TPS)));
else
    myCell{4} = myCell{3}./myCell{1}(101,101);  
end

% -----------------------------------------------------------------------
% Finally in myCell{5}, we place the calculated gamma for each point in the
% ROI.  d_criteria and DTA were given as inputs to this program.
% -----------------------------------------------------------------------

myCell{5} = sqrt((myCell{4}./d_criteria).^2 + (myCell{2}./DTA).^2);

%% Update gamma value and gamma spacial map
% -----------------------------------------------------------------------
% Finally, the gamma value is the minimum of the output of myCell{5} (the
% line above).  This is placed into a vector named ' gamma ', along with
% the position of that gamma within the map.  
% -----------------------------------------------------------------------
gamma(l,1) = min(min(myCell{5}));
gamma(l,2) = row_col(l,1);
gamma(l,3) = row_col(l,2);

% -----------------------------------------------------------------------
% Creates a gamma matrix with spatial position of the gamma point values
% calculated. This step is not necessary if positional information is not
% required.
% -----------------------------------------------------------------------
gamma_map(gamma(l,2),gamma(l,3))=gamma(l,1);

end

