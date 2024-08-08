var fetchPostsForUser = async (id, db) => {
    const user = await db.fetchUser(id);
    return user.posts;
};
