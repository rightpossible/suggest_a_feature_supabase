-- Create suggestions table
CREATE TABLE suggest_a_feature_suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    labels TEXT[] DEFAULT '{}',
    images TEXT[] DEFAULT '{}',
    author_id UUID NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    creation_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL DEFAULT 'requests',
    voted_user_ids UUID[] DEFAULT '{}',
    notify_user_ids UUID[] DEFAULT '{}'
);

-- Create comments table
CREATE TABLE suggest_a_feature_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_id UUID NOT NULL REFERENCES suggest_a_feature_suggestions(suggestion_id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    text TEXT NOT NULL,
    creation_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_from_admin BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create index for faster queries
CREATE INDEX idx_suggestion_id ON suggest_a_feature_comments(suggestion_id);