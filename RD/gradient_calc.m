
for num = 1:664
filename = [treatmentsite{num,2},treatmentsite{num,3}];
dose = open(filename);
[DX,DY] = gradient(dose.tps_dose);
mag_grad = sqrt(DX.^2 + DY.^2);
num_points = find(dose.tps_dose>=(0.1)*max(max(dose.tps_dose)));

treatmentsite{num,4} = mean(mag_grad(num_points));
num
end