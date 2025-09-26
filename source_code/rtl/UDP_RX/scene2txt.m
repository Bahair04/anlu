IMG = imread('scene_512_384.jpeg');
IMG = double(IMG);
color = zeros(size(IMG, 1), size(IMG, 2));
for i = 1 : size(IMG, 1)
    for j = 1 : size(IMG, 2)
        color(i, j) = bitshift(IMG(i, j, 1), -3) * 2 ^ 11 + bitshift(IMG(i, j, 2), -2) * 2 ^ 5 + bitshift(IMG(i, j, 3), -3);
        color(i, j) = min(max(color(i, j), 0), 65535);
    end
end
color = uint16(color);

fid = fopen('scene_512_384.txt', 'w');
bar = waitbar(0, 'write...');
fprintf(fid, 'F3 ED 7A 93 ');
for i = 1 : size(IMG, 1)
    for j = 1 : size(IMG, 2)
        fprintf(fid, '%02x %02x ', bitshift(color(i, j), -8), mod(color(i, j), 256));
        if j == size(IMG, 2)
            fprintf(fid, '\n');
        end
    end
    waitbar(i / size(IMG, 1));
end
close(bar);

img = zeros(size(IMG, 1), size(IMG, 2), 3);
for i = 1 : size(IMG, 1)
    for j = 1 : size(IMG, 2)
        img(i, j, 1) = bitshift(IMG(i, j, 1), -3) * 8;
        img(i, j, 2) = bitshift(IMG(i, j, 2), -2) * 4;
        img(i, j, 3) = bitshift(IMG(i, j, 3), -3) * 8;
    end
end
img = uint8(img);
imshow(img);