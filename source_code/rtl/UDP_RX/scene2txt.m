IMG = imread('scene.jpeg');
IMG = uint16(IMG);
color = zeros(size(IMG, 1), size(IMG, 2));
for i = 1 : size(IMG, 1)
    for j = 1 : size(IMG, 2)
        color(i, j) = bitshift(IMG(i, j, 1), -3) * 2 ^ 11 + bitshift(IMG(i, j, 2), -2) * 2 ^ 5 + bitshift(IMG(i, j, 3), -3);
        color(i, j) = min(max(color(i, j), 0), 65535);
    end
end
color = uint16(color);

fid = fopen('scene.txt', 'w');
fprintf(fid, 'F3 ED 7A 93 ');
for i = 1 : size(IMG, 1)
    for j = 1 : size(IMG, 2)
        fprintf(fid, '%x %x ', uint8(color(i, j) / 256), mod(color(i, j), 256));
        if j == size(IMG, 2)
            fprintf(fid, '\n');
        end
    end
end
