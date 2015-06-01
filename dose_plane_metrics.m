function [ mean_target_gradient, mean_target_dose, mean_pneumbra_gradient, ...
           mean_lowdose_gradient, mean_lowdose_dose, target, pneumbra, low_dose ] = dose_plane_metrics( TPS, MC )

%% Define Variables
target_lower_threshold   = 0.8;
pneumbra_lower_threshold = 0.2;
max_dose           = max(max(TPS));
TPS_target         = TPS;
TPS_pneumbra       = TPS;
TPS_low_dose            = TPS;
MC_ind             = find(MC>0);
noise_value        = 6.2;

%% Define matrix indices for target (greater than 80% of dose)
target_ind             = find(TPS<=target_lower_threshold*max_dose);
TPS_target(target_ind) = 0; %#ok<*FNDSB>
target_ind             = find(abs(TPS_target)>0);

ind_interest           = intersect(target_ind,MC_ind);
MC_interest_values     = MC(ind_interest);
TPS_interest_values    = TPS(ind_interest);
dose_diff_values       = ((MC_interest_values - TPS_interest_values)./(TPS_interest_values))*100;
dose_diff              = mean(dose_diff_values);
diff_stdev             = std(dose_diff_values);
num_points             = length(dose_diff_values);

target.dose_diff       = dose_diff;
target.stdev           = diff_stdev;
target.numpoints       = num_points;

%% Define pneumbra region (80%-20%)
pneumbra_ind_1 = find(TPS>target_lower_threshold*max_dose);
pneumbra_ind_2 = find(TPS<=pneumbra_lower_threshold*max_dose);

TPS_pneumbra(pneumbra_ind_1) = 0;
TPS_pneumbra(pneumbra_ind_2) = 0;

pneumbra_ind = find(TPS_pneumbra>0);

ind_interest        = intersect(pneumbra_ind,MC_ind);
MC_interest_values  = MC(ind_interest);
TPS_interest_values = TPS(ind_interest);
dose_diff_values    = ((MC_interest_values - TPS_interest_values)./(TPS_interest_values))*100;
dose_diff           = mean(dose_diff_values);
diff_stdev          = std(dose_diff_values);
num_points          = length(dose_diff_values);

pneumbra.dose_diff  = dose_diff;
pneumbra.stdev      = diff_stdev;
pneumbra.numpoints  = num_points;

%% Define low dose region (less than 20%, but larger than mapcheck noise)

lowdose_ind          = find(TPS>=pneumbra_lower_threshold*max_dose);
TPS_low_dose(lowdose_ind) = 0;
lowdose_ind          = find(TPS_low_dose > noise_value);



ind_interest        = intersect(lowdose_ind,MC_ind);
MC_interest_values  = MC(ind_interest);
TPS_interest_values = TPS(ind_interest);

ind_true_value      = find(MC_interest_values > noise_value);
dose_diff_values    = ((MC_interest_values(ind_true_value) - TPS_interest_values(ind_true_value))./(TPS_interest_values(ind_true_value)))*100;
dose_diff           = mean(dose_diff_values);
diff_stdev          = std(dose_diff_values);
num_points          = length(dose_diff_values);

low_dose.dose_diff  = dose_diff;
low_dose.stdev      = diff_stdev;
low_dose.numpoints  = num_points;

%% Computer parameters

TPS_normalized = (TPS./max_dose)*100;
[FX, FY]       = gradient(TPS_normalized);
F              = sqrt(FX.^2 + FY.^2);

mean_target_gradient   = mean(mean(abs(F(target_ind))));
mean_target_dose       = mean(mean(TPS(target_ind)));

mean_pneumbra_gradient = mean(mean(abs(F(pneumbra_ind))));

mean_lowdose_gradient  = mean(mean(abs(F(lowdose_ind))));
mean_lowdose_dose      = mean(mean(TPS(lowdose_ind)));


end

