function hlines = plot3_color(x, y, z, c, clmap, clim, varargin)
% PLOT3 with smoothly varying color
% plot3_color(x, y, z)              % coloring with respect to arclength of the curve
%                                   % x, y, z are vectors of the same length
                                    % each (x(i),y(i),z(i)) are 3D coordinates of the points of
                                    % curve
% plot3_color(x, y, z, c)           % coloring with respect to value of array c
%                                   % C must have the same size than x, y, z
% plot3_color(x, y, z, c, clmap)    % use colormap clmap (3 x P), each row
%                                   % is a RGB-triplet
% plot3_color(x, y, z, c, clmap, clim)  % use the lower-upper limit of in 2-elements clim
%                                   % same unit as C to color the lines
%                                   % By default clim fits the c range
% plot3_color(..., 'parent', ax)    % plot on axis AX
% plot3_color(..., 'linewidth', 3); % enlarge the linewidth
%
% NOTES:
%   1. If X, Y, Z are 2D (M x N) array, plot_color is carried out along
%      the first dimension, i.e., resulting N curves of length M.
%   2. The input color C must be the same size as X,Y,Z. 
%      Exception is: If X,Y,Z are MxN arrays, C can be vector of length M.
%      C will be automatic transposed/expanded as MxN to match X, Y and Z.
%   3. CLIM must be (2 x 1) vector if X, Y are vector. CLIM(1) is lower
%      limit and CLIM(2) is the upper; and CLIM(2) > CLIM(1).
%      In case X, Y is (M x N) array, CLIM must be (2 x N) array. If CLIM
%      has 2 elements, its will be automatic transposed/expanded as (2 x
%      N).
%   4. h = plot_color(...);            % return handles (multiple by curve)
%                                      % h{i} contains handles of curve i, k=1,...,N 
%   5. Set input arguments to [] to use the default
%
% EXAMPLE:
%   t = 0:pi/50:10*pi;
%   st = sin(t);
%   ct = cos(t);
%   plot3_color(st, ct, t, [], jet, [], 'linewidth', 3)
%   view(3)
%
% Author: Bruno LUONG <brunoluong.yahoo.com>
%
% See also: plot_color, plot3, colormap, colorbar

if isvector(z)
    z = z(:);
end
[ndata, ncurves] = size(z);
if isvector(x)
    x = x(:);
    if ncurves > 1
        x = repmat(x,[1 ncurves]);
    end
end
if isvector(y)
    y = y(:);
    if ncurves > 1
        y = repmat(y,[1 ncurves]);
    end
end

if nargin < 4 || isempty(c)
    % Compute arclengths
    dx = diff(x,1,1);
    dy = diff(y,1,1);
    dz = diff(z,1,1);
    c = [zeros(1,ncurves); 
         cumsum(sqrt(dx.^2+dy.^2+dz.^2),1)];
else
    if isvector(c)
        c = c(:);
    end
    if ncurves > 1 && size(c,2)==1
        c = repmat(c,[1 ncurves]);
    end
    if size(c,1) ~= ndata
        error('size(c) must match size(z)')
    end
end

if nargin < 5 || isempty(clmap)
    clmap = colormap();
end
ncolors = size(clmap,1);

if nargin < 6 || isempty(clim)
    % auto range
    cmin = min(c,[],1);
    cmax = max(c,[],1);
    clim = [cmin; cmax];
else
    if isvector(clim) && length(clim)==2
        clim = repmat(clim(:),[1 ncurves]);
    end
end

% Map C to colormap index
cmin = clim(1,:);
cmax = clim(2,:);
if any(cmax <= cmin)
    error('cmax must be > cmin')
end
% Under R2006B, you can replace by two commands by BSXFUN
% cn = ncolors .* (c - cmin) ./ (cmax-cmin);
cn = bsxfun(@minus, c, cmin);
cn = bsxfun(@times, cn, ncolors./(cmax-cmin));

% Trick, process n curves as single one, separated by NaN
x(end+1,:) = NaN;
x = x(:);
y(end+1,:) = NaN;
y = y(:);
cn(end+1,:) = NaN;
z = z(:);
cn(end+1,:) = NaN;
cn = cn(:);
% Color of the middle of the unitary segments
cmid = 0.5*(cn(1:end-1)+cn(2:end));
cmid = round(cmid+0.5);
idx = [0; find(diff(cmid))]+1;
clidx = cmid(idx)'; % reshape in row
keep = find(~isnan(clidx));
clidx = min(max(clidx,1),ncolors);
for i = length(keep):-1:1 % reverse loop to automatic allocate array H and J1
    k = keep(i);
    j = idx(k):idx(k+1);
    h(i) = line('XData',x(j),'YData',y(j), 'ZData',z(j),...
                'color',clmap(clidx(k),:), ...
                varargin{:});
    j1(i) = j(1);      
end
if nargout > 0
    % Put in cell, group by curve
    n = floor((j1 - 1) / (ndata+1)) + 1;
    k = 1:length(h);
    hlines = accumarray(n(:), k(:), [], @(k) {h(k)});
end
end % plot3_color
