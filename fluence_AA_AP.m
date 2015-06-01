function [ area, perimeter ] = fluence_AA_AP( cp_fluence, pixel_size )

    binary_image = im2bw(cp_fluence,0);
    L            = bwlabel(binary_image);
    s            = regionprops(L, 'Area', 'BoundingBox'); %#ok<*MRPBW>
    area_values  = [s.Area];
distinct_regions = length(area_values);
       perimeter = 0;

    for i = 1:distinct_regions

        perimeter_image = ismember(L,i);
        per_val = regionprops(perimeter_image,'Perimeter');
        perimeter = perimeter + per_val.Perimeter;

    end
    
perimeter = perimeter*pixel_size;
area      = sum(area_values)*(pixel_size)*(pixel_size);

end