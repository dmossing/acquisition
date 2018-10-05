function final_ims = gen_crop_ims(bg_diam, sm_diam, resize_factor, moviefname)
im_array = load(moviefname);
im_array = im_array.images;

final_ims = zeros(bg_diam, bg_diam, size(im_array,3)*2);
for i = 1:size(im_array,3)
    x = im_array(:,:,i);
    r = imresize(x,resize_factor);
    cric = circle_crop(r, bg_diam,bg_diam,x_dim);
    lil_circ = circle_crop(r,sm_diam,bg_diam,x_dim);
    final_ims(:,:,i*2-1) = cric;
    final_ims(:,:,i*2) = lil_circ;
end
end

function cropped=circle_crop(im, diam, o_diam, x_dim)
II = im;
[p3, p4] = size(II);
q1 = diam; % size of the crop box
i3_start = floor((p3-q1)/2); % or round instead of floor; using neither gives warning
i3_stop = i3_start + q1;

i4_start = floor((p4-q1)/2);
i4_stop = i4_start + q1;

im = II(i3_start:i3_stop, i4_start:i4_stop, :);


k = strel('disk',diam/2,0);
k = uint8(k.Neighborhood);
size(im)
size(k)
cropped = im.*k;
k(k==0)=128;
k(k==1)=0;
cropped = cropped+k;
if size(k,1)<o_diam
    new = repmat([128],o_diam,o_diam);
    start = uint16(ceil(o_diam/2-diam/2))
    endy = uint16(ceil(o_diam/2+diam/2))
    new(start:endy,start:endy)=cropped;
    cropped =uint8(new);
end
if size(k,1)>o_diam
    new = repmat([128],o_diam,o_diam);
    start = 1
    endy = diam
    new(start:endy,start:endy)=cropped(start:endy, start:endy);
    cropped =uint8(new);
end
if x_dim>o_diam
    new = repmat([128],o_diam, x_dim);
    s = x_dim/2-o_diam/2+1;
    e = x_dim/2+o_diam/2
    size(cropped)
    size(new(:,s:e))
    new(:,s:e)=cropped;
    cropped = uint8(new);
end

    

%figure;imshow(cropped);
end

